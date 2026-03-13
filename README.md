# Greybeard

Useful automated code reviews by AI

## Directories

- `modules`: general purpose rules to focus on
- `specifics`: things specific to your team or project
- `repos`: clone all the repos you care about in here

## Usage

With Claude:

```
review <branch-name> in <repo-name>
```

## How it works

1. Diff the branch against `origin/main`
2. Evaluate in parallel against each module (general best practices)
3. Evaluate in parallel against specifics (team/project rules)
4. Generate a summary of potential issues
5. Fact-check each issue against the actual codebase to eliminate false positives
6. Output PASS/FAIL per module with locations and suggested fixes for failures
