# Sources

This directory contains cloned repositories that serve as **shared domain knowledge** for all workflows. These are read-only references—not working development environments.

**Important:** When comparing against other repos, always use their `main` branch and pull to ensure it's up to date.

---

## Adding Repositories

Clone repos you want to analyze:

```bash
git clone <repo-url> sources/<repo-name>
```

## Documenting Your Repos

For each repo you add, document:

### Repository Name (`repo-name/`)
Brief description of what this repo does.

**Key domains:** List the main business domains covered

---

## Cross-Repo Relationships

If your repos interact with each other, document the relationships:

```
┌─────────────────┐
│   Frontend      │
└────────┬────────┘
         │ API calls
         ▼
┌─────────────────┐      ┌─────────────────┐
│   Backend API   │◄────►│  External Svc   │
└─────────────────┘      └─────────────────┘
```

### Integration Points

| From | To | What |
|------|----|------|
| Frontend | Backend API | User data, auth |
| Backend | External Svc | Third-party integration |

---

## Using Sources in Workflows

### Code Review
1. Check out the branch to review under `sources/{repo}/`
2. Pull latest `origin/main` for comparison
3. Cross-repo analysis: check related repos if changes touch integration points

### Knowledge Extraction
1. Run the pipeline against `sources/{repo}/`
2. Note cross-repo dependencies in domain records
3. Align ubiquitous language across repos where terms overlap

---

## Notes

- These repos are not set up as working development environments
- Tests, console, and local servers may not work
- Use for read-only analysis and reference only
