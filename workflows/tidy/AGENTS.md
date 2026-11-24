# Tidy Workflow

Cleans up what an implementation track left on this machine once its work is merged or abandoned: the git worktree and local branch, the worktree's Docker containers, images, volumes and databases, dev servers started for it, and stray screenshots. It keeps anything still in use and anything holding work that isn't on `origin`.

## Purpose

`implement --worktree`, `validate` and `improve` start sibling worktrees, per-worktree stacks (`origami_<n>_app`, `_test`, `_redis`), per-worktree databases on the shared Postgres, webpack servers, and seed data. Nothing removes them, so they pile up: a 2.7 GB image per stack, a dozen exited containers, databases nobody uses. Tidy finds everything one track created, checks that nothing unrecoverable goes with it, removes it, and reports what it kept and why.

## Inputs

**`tidy`** with one of:
- nothing: the track this thread worked on (its worktree or branch, from the conversation or `bb status`)
- a ticket ID (`PROD-2387`), a branch (`d/prod-2387-onboarding-invite-adults`), or a worktree path
- optionally `in <repo>`, `--dry-run` (list only, remove nothing), `--keep-branch`, `--keep-data` (leave databases and the image)

The **suffix** names the track's resources: the ticket number (`2387`), or the worktree directory's suffix after `<checkout>-`.

## Outputs

- The resources removed, and those kept with the reason for each.
- Gitignored notes from the worktree (`claude_notes/`) copied into the main checkout's `claude_notes/` before the worktree goes.
- No commits, no pushes, and no remote branch deletion. GitHub deletes merged branches itself; ask before touching a remote.

## Execution

Run the steps in order. `git worktree`, `docker`, and anything that reads other processes need the Bash sandbox off. The sandbox blocks the worktree's `.git/worktrees/<name>` index and the Docker socket, and it hides processes it didn't start.

### 1. Resolve the track

- Main checkout: `git -C <worktree> rev-parse --git-common-dir`, or the repo's checkout under `~/workspace/<repo>`.
- Worktree: `git -C <main> worktree list --porcelain`. Match the path (`<checkout>-<suffix>`) or the branch.
- Branch, its PR (`gh pr list -R <owner>/<repo> --head <branch> --state all --json number,state,mergedAt,mergeCommit`), and the suffix.

### 2. Safety gate: nothing unrecoverable is lost

Each check below must pass before its resource is removed. A failed check keeps that resource and lists it under **Kept**. Never use `git stash` (worktrees share the stash list with the main checkout, and a no-op stash followed by `pop` applies someone else's WIP), `git reset --hard`, or `git checkout -- .` to make a check pass.

- **Worktree is clean.** `git -C <worktree> status --porcelain` shows nothing tracked as modified or added. Untracked files that aren't gitignored are listed and kept unless they're clearly generated.
- **Branch is safe to delete.** One of these:
  - The PR merged, and the merge carries the branch's content: `git diff --stat <branch tip> <merge commit> -- $(git diff --name-only $(git merge-base <branch tip> <merge commit>) <branch tip>)` prints nothing. Squash merges need this; `git branch -d` alone can't tell.
  - The PR is closed unmerged, and the user said the track is abandoned.
  - The local tip equals `origin/<branch>` (nothing unpushed). Otherwise keep the branch and say how many commits only exist locally.
- **Image is unused.** `docker ps -a --filter ancestor=<image id>` lists no container outside this track. Other worktrees reuse each other's images (`app:2387` ran `origami_2658_app`).
- **A database belongs to this track only.** Its name ends in `_<suffix>`, or the track's containers point at it via `DATABASE_URL`.

### 3. Inventory

Find everything the track created. Prefer evidence (mounts, env, names) over guessing:

| Resource | How to find it |
|---|---|
| Repo teardown script | `<worktree>/bin/worktree-teardown`: if it exists, it is the first choice for the stack (step 5) |
| Containers | `docker ps -a --format '{{.Names}}'` matching `_<suffix>_` or `_<suffix>$`, plus any container whose mounts include the worktree path (`docker inspect -f '{{range .Mounts}}{{.Source}} {{end}}'`) |
| Images | tags ending `:<suffix>` (`app:2387`), and any image built only for those containers |
| Volumes / networks | `docker volume ls` and `docker network ls` filtered by the suffix. Never the shared `shared_dev_network` |
| Databases | `docker exec <shared postgres> psql -U postgres -Atc "select datname from pg_database where datname like '%\_<suffix>' escape '\'"`. Start the shared Postgres if it is stopped, and say so |
| Dev servers | processes whose command line includes the worktree path (`ps -axo pid,command`), e.g. `webpack serve --port 44` |
| Notes | `<worktree>/claude_notes/*` (gitignored, so lost with the worktree) |
| Screenshots | `<main>/.playwright-mcp/` and `<main>/*.png` named with the branch slug. Copies already in thread storage stay |

Shared infrastructure is never removed: `origami_postgres`, `origami_redis`, `care_postgres`, `care_redis`, the main checkout's `origami_app` / `care_app`, and other tracks' containers. Seed data the track wrote into shared dev databases (for example CP's dev DB) is reported, not deleted.

### 4. Plan

Print one list: what will be removed and what will be kept (with the failed check or the reason). With `--dry-run`, stop here.

The `tidy` request is the go-ahead for everything that passed step 2. Ask once, before removing anything, only when an item failed a check and the user might still want it gone: an unpushed branch, a dirty worktree, a closed-unmerged PR.

### 5. Remove

Copy first, delete last:

1. Copy `<worktree>/claude_notes/*` to `<main>/claude_notes/`, without overwriting files that differ.
2. Stop the track's dev servers (`kill <pid>`; tell the user this runs outside the sandbox).
3. Stack: run `bin/worktree-teardown` from the worktree when it exists. Otherwise `docker rm -f <containers>`, then `docker volume rm` / `docker network rm` for the track's own.
4. Databases: `dropdb -U postgres --if-exists <name>` inside the shared Postgres container, then re-query to confirm none are left.
5. Images that passed the unused check: `docker rmi <image>`. If Docker reports a conflict, keep the image and name the container using it.
6. Worktree: `git -C <main> worktree remove <path>`. Use `--force` only after step 2 passed, because the untracked files left are gitignored ones already copied. Then `git -C <main> worktree prune`.
7. Branch: `git -C <main> branch -D <branch>`, unless `--keep-branch` was passed.
8. Screenshots in the main checkout named for this branch.

### 6. Report

```
## Tidied <track>
Removed: worktree <path> · branch <name> · containers <n> · databases <n> · image <tag> (<size>) · <other>
Kept: <resource>: <why> (one line each, or "Nothing")
Notes saved: <files copied to claude_notes/>
Left alone: <shared or other-track resources the user might expect gone, and why>
```

## Components

Single-file workflow: no lenses, pipeline stages, or templates.

## Notes

- origami_claims worktree stacks so far (no `bin/worktree-setup`, so they're hand-built): containers `origami_<n>_app` / `_test` / `_redis`; image `app:<n>`; databases `origami_claims_development_<n>`, `reverse_etl_development_<n>`, `origami_test_<n>`, `fairhealth_test_<n>`, `pricer_test_<n>`, `ihq_test_<n>`, `reverse_etl_test_<n>` on `origami_postgres`.
- `git worktree remove --force` deletes gitignored files (notes, the `client/node_modules` symlink). That is why step 5 copies notes first.
- `last-reviewed-sha.sh` and the code-review run records live in `$GREYBEARD_DATA`, not in the worktree, so tidying never loses review history.
