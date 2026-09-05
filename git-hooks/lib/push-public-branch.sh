# Shared body for pre-push: pushes a local `public` branch to the `gh`
# remote whenever a push to master is going through, so the public mirror
# never lags behind what was just pushed privately. Sourced, not executed.
#
# Contract: push_public_branch <repo_root>
# No-op if there's no local `public` branch or no `gh` remote configured.
# Best-effort: a failed push here is reported but does not block the master
# push it rode along with (a GitHub-specific hiccup shouldn't stop a push to
# the private origin). See ./sync-public-branch.sh for the local
# fast-forward step (post-commit/post-merge) this builds on -- by the time
# this runs, local public should already match local master.

push_public_branch() {
  repo_root="$1"

  git -C "$repo_root" show-ref --verify --quiet refs/heads/public || return 0
  git -C "$repo_root" remote get-url gh >/dev/null 2>&1 || return 0

  push_output=$(mktemp "${TMPDIR:-/tmp}/push-public-branch.XXXXXX")
  if git -C "$repo_root" push gh public:public >"$push_output" 2>&1; then
    echo "push-public-branch: pushed public to gh in $repo_root" >&2
  else
    echo "push-public-branch: failed to push public to gh in $repo_root -- push it yourself when ready. Output:" >&2
    cat "$push_output" >&2
  fi
  rm -f "$push_output"
}
