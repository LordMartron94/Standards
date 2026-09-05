# Shared body for the pre-merge-commit / pre-push gates. Sourced, not
# executed: defines run_deep_review_gate and returns.
#
# Contract: run_deep_review_gate <repo_root> <diff_text> <event_label>
# Returns 0 to allow the merge/push, 1 to block it. Prints a concise status
# line to stderr for every outcome (so it always shows up in the normal
# `git merge`/`git push` output, even when nothing needs to happen) but
# never Claude's raw response -- that goes to a logfile
# (<git-dir>/deep-review-gate.log, overwritten fresh on every run) so a
# `git push` doesn't get flooded with report text.
#
# See adr/0001-deep-review-gate-on-master-merges.md for why this exists and
# what it deliberately does not cover (--no-verify, standalone submodule
# clones with no .claude/skills to review against).

run_deep_review_gate() {
  repo_root="$1"
  diff_text="$2"
  event_label="$3"

  git_dir=$(git -C "$repo_root" rev-parse --absolute-git-dir)
  log_file="$git_dir/deep-review-gate.log"
  : >"$log_file"
  echo "deep-review gate log -- $event_label" >>"$log_file"

  # The deep-review skill (and STYLE_GUIDE.md/AGENT.md it reads) only exists
  # checked out inside a MergeSource workspace. A submodule cloned standalone
  # has none of it -- walk up from repo_root looking for it; skip (allow) if
  # nothing is found, rather than blocking on a review that cannot run here.
  standards_root="$repo_root"
  while [ ! -f "$standards_root/.claude/skills/deep-review/SKILL.md" ]; do
    parent=$(dirname "$standards_root")
    if [ "$parent" = "$standards_root" ]; then
      echo "deep-review gate: no .claude/skills/deep-review found in '$repo_root' or any parent directory -- skipping ($event_label allowed; this checkout has no MergeSource workspace to review against)." >&2
      return 0
    fi
    standards_root="$parent"
  done

  if ! command -v claude >/dev/null 2>&1; then
    echo "deep-review gate: 'claude' CLI not found on PATH -- blocking $event_label. Install Claude Code, or bypass this one merge/push with --no-verify if that's intended." >&2
    return 1
  fi

  echo "deep-review gate: reviewing $event_label (this can take a bit)..." >&2

  diff_file=$(mktemp "${TMPDIR:-/tmp}/deep-review-gate.XXXXXX.diff")
  stderr_file=$(mktemp "${TMPDIR:-/tmp}/deep-review-gate.XXXXXX.stderr")
  printf '%s\n' "$diff_text" >"$diff_file"

  prompt="A merge to master is pending in ${repo_root} (${event_label}) and must be reviewed before it is allowed to proceed.

Follow the review method in .claude/skills/deep-review/SKILL.md, sections 3 (review axes), 4 (severity model) and 5 (write the report) -- but use the diff already saved at ${diff_file} as the exact and only scope. Do NOT run that skill's own git-diff scope-detection commands from section 2; this diff supersedes them.

Write the report as usual (section 5), then render it (section 6).

Then, as the very last line of your final message, and nothing after it, print exactly one of:
DEEP_REVIEW_GATE: PASS
DEEP_REVIEW_GATE: BLOCK critical=<N> high=<N>
using the real Critical/High counts from your findings. PASS means zero Critical and zero High findings."

  claude_status=0
  result_json=$(cd "$standards_root" && claude -p "$prompt" \
    --output-format json \
    --dangerously-skip-permissions \
    --max-budget-usd 3 \
    2>"$stderr_file") || claude_status=$?
  rm -f "$diff_file"

  {
    echo "--- claude exit status: $claude_status ---"
    echo "--- stderr ---"
    cat "$stderr_file"
    echo "--- raw stdout (--output-format json) ---"
    printf '%s\n' "$result_json"
  } >>"$log_file"
  rm -f "$stderr_file"

  if [ "$claude_status" -ne 0 ]; then
    echo "deep-review gate: claude invocation failed (exit $claude_status) -- blocking $event_label. Details: $log_file" >&2
    return 1
  fi

  result_text=$(printf '%s' "$result_json" | jq -r '.result // empty' 2>/dev/null) || result_text=""
  {
    echo "--- parsed .result ---"
    printf '%s\n' "$result_text"
  } >>"$log_file"

  if [ -z "$result_text" ]; then
    echo "deep-review gate: could not parse claude's JSON output -- blocking $event_label. Details: $log_file" >&2
    return 1
  fi

  verdict=$(printf '%s\n' "$result_text" | grep '^DEEP_REVIEW_GATE:' | tail -1)

  case "$verdict" in
    "DEEP_REVIEW_GATE: PASS")
      echo "deep-review gate: PASS -- $event_label allowed." >&2
      return 0
      ;;
    "DEEP_REVIEW_GATE: BLOCK"*)
      echo "deep-review gate: BLOCKED -- $verdict" >&2
      report_line=$(printf '%s\n' "$result_text" | grep -i 'results/reviews/' | tail -3)
      [ -n "$report_line" ] && printf '%s\n' "$report_line" >&2
      echo "deep-review gate: fix the findings above, then retry. Full response: $log_file. Bypass with --no-verify if you must merge/push anyway." >&2
      return 1
      ;;
    *)
      echo "deep-review gate: no parseable verdict in claude's response -- blocking $event_label to be safe. Details: $log_file" >&2
      return 1
      ;;
  esac
}
