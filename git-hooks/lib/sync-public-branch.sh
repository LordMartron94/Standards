# Shared body for the post-commit / post-merge hooks: keeps a local
# `public` branch fast-forwarded to `master` automatically, so Mr. Hoorn
# never has to `git merge master` into public by hand. Sourced, not
# executed.
#
# Contract: sync_public_branch <repo_root>
# Best-effort and non-blocking -- post-commit/post-merge fire after the real
# event already happened, so there's nothing left to abort. Never touches a
# remote (pushing public is still a deliberate, separate step) and never
# force-moves public when it has diverged from master -- only ever a plain
# fast-forward. Narration goes to stderr.

sync_public_branch() {
  repo_root="$1"

  branch=$(git -C "$repo_root" rev-parse --abbrev-ref HEAD)
  [ "$branch" = "master" ] || return 0

  git -C "$repo_root" show-ref --verify --quiet refs/heads/public || return 0

  master_sha=$(git -C "$repo_root" rev-parse master)
  public_sha=$(git -C "$repo_root" rev-parse public)

  [ "$master_sha" = "$public_sha" ] && return 0

  if git -C "$repo_root" merge-base --is-ancestor public master; then
    git -C "$repo_root" update-ref refs/heads/public "$master_sha"
    echo "sync-public-branch: fast-forwarded public to master (${master_sha}) in $repo_root -- push it to your public remote when ready." >&2
  else
    echo "sync-public-branch: public has commits master doesn't (diverged) in $repo_root -- not touching it automatically. Merge or rebase public onto master by hand." >&2
  fi
}
