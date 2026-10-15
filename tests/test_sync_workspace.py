"""Exercise workspace synchronization against disposable local Git repositories."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "sync_workspace.sh"
SERVER_PREFIX = "ssh://git@localhost:22222/home/git/git-repos/"


class WorkspaceSyncTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="workspace-sync-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.workspace = self.root / "workspace"
        self.remotes = self.root / "remotes"
        self.remotes.mkdir()
        self.environment = os.environ.copy()
        self.environment.update({
            "GIT_CONFIG_GLOBAL": str(self.root / "gitconfig"),
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_TERMINAL_PROMPT": "0",
            "GIT_AUTHOR_NAME": "Workspace sync regression",
            "GIT_AUTHOR_EMAIL": "sync@example.invalid",
            "GIT_COMMITTER_NAME": "Workspace sync regression",
            "GIT_COMMITTER_EMAIL": "sync@example.invalid",
        })
        # Test clones must never reach SSH or GitHub, even after a regression.
        self.environment["GIT_ALLOW_PROTOCOL"] = "file"
        self.git(self.root, "config", "--global", "protocol.file.allow", "always")
        self.git(self.root, "config", "--global",
                 "url." + self.remotes.as_uri() + "/.insteadOf", SERVER_PREFIX)
        self.git(self.root, "init", "--initial-branch=master", str(self.workspace))
        script = self.workspace / "infra/standards/sync_workspace.sh"
        script.parent.mkdir(parents=True)
        shutil.copy2(SCRIPT, script)
        hooks = self.workspace / "tools/scripts/install-git-hooks.sh"
        hooks.parent.mkdir(parents=True)
        hooks.write_text('#!/bin/sh\nprintf "%s\\n" "$@" >> hooks.log\n')
        hooks.chmod(0o755)

    def git(self, directory, *arguments):
        return subprocess.check_output(
            ["git", "-C", str(directory), *arguments],
            env=self.environment, text=True, stderr=subprocess.PIPE,
        ).strip()

    def commit(self, directory):
        self.git(directory, "add", ".")
        self.git(directory, "commit", "-m", "Fixture")

    def remote(self, name, contents):
        source = self.root / (name.replace("/", "_") + "-source")
        self.git(self.root, "init", "--initial-branch=master", str(source))
        (source / "README.md").write_text(contents)
        self.commit(source)
        target = self.remotes / (name + ".git")
        target.parent.mkdir(parents=True, exist_ok=True)
        self.git(self.root, "clone", "--bare", str(source), str(target))
        return target

    def sync(self, success=True):
        result = subprocess.run(
            ["bash", "infra/standards/sync_workspace.sh"],
            cwd=self.workspace, env=self.environment, capture_output=True, text=True,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def test_vendored_sources_skip_submodule_initialization_and_hooks(self):
        source = self.workspace / "external/sqlite3"
        source.mkdir(parents=True)
        (source / "sqlite3.c").write_text("vendored source fixture\n")
        (self.workspace / "workspace.conf").write_text("external sqlite3 - -\n")
        self.commit(self.workspace)
        result = self.sync()
        self.assertIn("Verified vendored source: external/sqlite3", result.stdout)
        self.assertNotIn("Initializing missing payload", result.stdout)
        self.assertFalse((self.workspace / "hooks.log").exists())
        self.assertFalse((self.workspace / ".gitmodules").exists())
        self.assertEqual((source / "sqlite3.c").read_text(), "vendored source fixture\n")

    def test_stale_metadata_is_preserved_and_new_repository_is_cloned(self):
        old_remote = self.remote("old/nexus", "old implementation\n")
        new_remote = self.remote("language/c/core/nexus", "new implementation\n")
        stale = self.workspace / ".git/modules/libs/nexus"
        stale.parent.mkdir(parents=True)
        self.git(self.root, "clone", "--bare", str(old_remote), str(stale))
        old_head = self.git(stale, "rev-parse", "HEAD")
        (self.workspace / "workspace.conf").write_text(
            "libs nexus language/c/core/nexus Nexus-C\n")
        self.commit(self.workspace)
        self.sync()
        checkout = self.workspace / "libs/nexus"
        self.assertEqual(self.git(checkout, "rev-parse", "HEAD"),
                         self.git(new_remote, "rev-parse", "HEAD"))
        self.assertEqual(self.git(stale, "rev-parse", "HEAD"), old_head)
        self.assertEqual(self.git(self.workspace, "config", "-f", ".gitmodules",
                                  "--get", "submodule.libs/nexus-2.path"), "libs/nexus")
        self.assertEqual(self.git(checkout, "rev-parse", "public"),
                         self.git(checkout, "rev-parse", "master"))
        self.assertEqual(self.git(checkout, "remote", "get-url", "gh"),
                         "git@github.com:LordMartron94/Nexus-C.git")
        modules = (self.workspace / ".gitmodules").read_bytes()
        self.sync()
        self.assertEqual((self.workspace / ".gitmodules").read_bytes(), modules)
        self.assertEqual(self.git(stale, "rev-parse", "HEAD"), old_head)
        self.assertEqual((self.workspace / "hooks.log").read_text().splitlines(),
                         ["libs/nexus", "libs/nexus"])

    def test_existing_uninitialized_submodule_is_restored(self):
        self.remote("language/c/core/nexus", "new implementation\n")
        url = SERVER_PREFIX + "language/c/core/nexus.git"
        self.git(self.workspace, "submodule", "add", url, "libs/nexus")
        (self.workspace / "workspace.conf").write_text(
            "libs nexus language/c/core/nexus -\n")
        self.commit(self.workspace)
        self.git(self.workspace, "submodule", "deinit", "-f", "--", "libs/nexus")
        result = self.sync()
        self.assertIn("Initializing missing payload", result.stdout)
        self.assertTrue((self.workspace / "libs/nexus/.git").exists())
        self.assertEqual((self.workspace / "hooks.log").read_text(), "libs/nexus\n")

    def test_missing_vendored_source_has_an_explicit_error(self):
        (self.workspace / "workspace.conf").write_text("external sqlite3 - -\n")
        self.commit(self.workspace)
        result = self.sync(success=False)
        self.assertIn("no configured repository", result.stderr)
        self.assertNotIn("Adding submodule", result.stdout)


if __name__ == "__main__":
    unittest.main()
