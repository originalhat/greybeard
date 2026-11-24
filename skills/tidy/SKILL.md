---
name: tidy
description: >-
  Clean up what an implementation track left on this machine once its work is
  merged or abandoned: the git worktree and local branch, the worktree's Docker
  containers, images, volumes and per-worktree databases, dev servers started
  for it, and stray screenshots, after copying its gitignored notes. Use when
  the user says "tidy", "/tidy", "tidy PROD-2387", "clean up locally", "tear
  down the worktree", "clean up after this ticket", or "remove the stack for
  <branch>". Checks first that the worktree is clean and the branch's content
  is merged (squash-aware) or pushed, keeps anything still used by another
  worktree (shared images, shared Postgres and Redis), never stashes or resets,
  and never deletes remote branches. `--dry-run` lists without removing;
  `--keep-branch` and `--keep-data` narrow it.
---

# Tidy

Run `${CLAUDE_PLUGIN_ROOT}/workflows/tidy/AGENTS.md`.

**Trigger:** `tidy [<ticket | branch | worktree path>] [in <repo>] [--dry-run] [--keep-branch] [--keep-data]`. With no target, it tidies the track this thread worked on.

That file holds the whole procedure: resolve the track → safety gate (clean worktree, merged-or-pushed branch, image unused elsewhere) → inventory by suffix, mounts and env → one plan list → remove (notes copied first, branch deleted last) → a short report of what was removed and what was kept, with the reason for each.
