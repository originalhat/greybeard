# Phase 5 — Sync runbooks to the app repo (end of shift)

Publish the canonical runbooks into the actual app repo as a branch + pull request, so engineers browsing the repo (and the in-repo `/oncall` command) get the shift's new and updated runbooks. Run this **once at the end of an on-call shift**, after the shift's tickets have been `capture`d.

**Direction is one-way.** `$GREYBEARD_DATA/output/on-call/runbooks/{repo}/` stays the source of truth; this phase copies *from* there *into* the app repo. Never sync back the other way — edits happen in the canonical store, then flow out here.

## Input

A target repo (`origami_claims`, `care_platform`, `sana_mobile`). Reads the canonical runbooks for that repo and opens a PR against it.

## Prerequisites

- The app-repo clone at `$GREYBEARD_DATA/sources/{repo}/` has a pushable `origin` and `gh` is authenticated (`gh auth status`). This clone is what we push from — **not** the user's live working checkout.
- The clone is clean and on `main`. If it has local changes, stop and tell the engineer rather than committing over them.

## Steps

### Phase 5a — Preflight

```bash
git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" fetch origin
git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" checkout main
git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" pull --ff-only
git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" status --short   # must be clean
```

If `status` isn't clean, stop. Decide the in-repo target directory — default **`docs/runbooks/`** (where the legacy runbooks already live).

### Phase 5b — Copy the canonical hierarchy in (non-destructive to legacy files)

Mirror `runbooks/{repo}/` (the `INDEX.md` + each domain subfolder) into the target dir. Preserve the domain hierarchy: `docs/runbooks/{domain}/{scenario}.md` and `docs/runbooks/INDEX.md`.

- **Sync each domain subtree with `--delete`** so renamed/removed scenarios propagate — this is safe because it only touches that domain subdir:
  ```bash
  SRC="${GREYBEARD_DATA:-$HOME/.greybeard-data}/output/on-call/runbooks/{repo}"
  DST="${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}/docs/runbooks"
  for d in "$SRC"/*/; do
    domain=$(basename "$d")
    rsync -a --delete "$d" "$DST/$domain/"
  done
  cp "$SRC/INDEX.md" "$DST/INDEX.md"
  ```
- **Do not delete the legacy flat runbooks** at the top of `docs/runbooks/` (`on-call-runbook.md`, `invoicing-runbook.md`, `broker-payment-runbook.md`) — the in-repo `/oncall` command still reads them. They coexist with the hierarchy until a deliberate cleanup PR retires them and repoints `/oncall`.

### Phase 5c — Review the diff

```bash
git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" add docs/runbooks
git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" status --short
git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" diff --staged --stat
```

Build the change summary from this: which scenarios are **new**, which **updated**, and which tickets drove them (pull ER/PROD refs from the runbook History lines and `.oncall-state.json`). If the diff is empty, there's nothing to sync — say so and stop.

### Phase 5d — Confirm, branch, commit, push, PR (confirmation-gated)

This writes to the real repo. Show the engineer the change summary and the proposed PR title/body, and proceed only on explicit approval; let them edit first.

```bash
REPO="${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}"
BRANCH="oncall/runbook-sync-$(date +%Y-%m-%d)"
git -C "$REPO" checkout -b "$BRANCH"
git -C "$REPO" commit -m "on-call: sync runbooks ($(date +%Y-%m-%d))"   # body: the change summary
git -C "$REPO" push -u origin "$BRANCH"
gh -R origami-medical/{repo} pr create --base main --head "$BRANCH" \
  --title "On-call runbook sync — $(date +%Y-%m-%d)" \
  --body "<change summary>"
```

- Restore the clone afterward: `git -C "$REPO" checkout main` so the next workflow run starts clean.
- PHI-free: the runbooks already are, so nothing to scrub — but do a quick scan of the staged diff to be sure no real identifiers slipped in.

### Phase 5e — Record the sync

Update `.oncall-state.json` for the repo with a `last_synced` object: `{ "date": "{YYYY-MM-DD}", "pr_url": "…", "branch": "…" }`. Report the PR URL to the engineer.

## Guidelines

- One-directional: canonical store → app repo. Never edit runbooks in the app repo and sync back.
- Non-destructive to the legacy flat runbooks; destructive only within each domain subtree (so renames/removals propagate).
- Confirmation-gated — it's an external write and a PR. Nothing pushed without explicit approval.
- If `gh`/push isn't available, stop and report; don't leave a half-synced branch.

## Next

The engineer reviews and merges the PR in the app repo. The canonical store is unchanged and remains the source of truth for the next shift.
