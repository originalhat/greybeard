# Phase 2: Screenshotter

- **Role:** Visual Capture Agent
- **Model:** Sonnet
- **Input:** Running dev server or deployed URL for `sources/{repo}/`
- **Output:** Screenshots in `output/{repo}/screenshots/` + manifest

## Mission

Capture representative screenshots of key pages and states at multiple viewports for visual analysis by the Analyzer (Phase 3). Quality and coverage matter more than quantity.

## Prerequisites

The app must be runnable or accessible:
- **Local dev server:** `npm run dev`, `yarn dev`, `rails server`, etc.
- **Deployed URL:** Staging or preview environment

**If neither is available, this phase is skipped.** The workflow proceeds with static-only analysis. Note the skip in the workflow output.

## Process

### 1. Identify Routes/Pages

Read the app's routing configuration to find all unique views:
- React: `react-router` config, `next.config.js`, `app/` directory structure
- Rails: `config/routes.rb`
- Vue: `router/index.js`
- Other: look for page-level components or URL patterns

**Prioritize** (capture these first):
- Landing/home page
- Primary navigation states
- Forms (empty, filled, error states)
- Data tables/lists
- Detail/show pages
- Modal/dialog states
- Empty states
- Error pages (404, 500)

### 2. Configure Viewports

Capture each page at three standard viewports:

| Name | Width | Height | Represents |
|------|-------|--------|-----------|
| Mobile | 375 | 812 | iPhone 14 |
| Tablet | 768 | 1024 | iPad portrait |
| Desktop | 1440 | 900 | Standard desktop |

### 3. Capture

Use Playwright headless browser for each page at each viewport:

```
1. Set viewport dimensions
2. Navigate to the page
3. Wait for network idle + DOM stable
4. Capture full-page screenshot
5. Save as: {page-name}-{viewport}.png
```

**Naming convention:** Lowercase, hyphens, descriptive. Examples:
- `home-desktop.png`
- `login-form-mobile.png`
- `patient-list-tablet.png`
- `modal-confirm-delete-desktop.png`

### 4. Interactive States (If Feasible)

For key interactive elements, capture additional states:
- **Hover:** Button hover states, link hover
- **Open:** Dropdowns, menus, modals
- **Filled:** Forms with data
- **Error:** Form validation errors
- **Loading:** Skeleton states if visible

These are bonus captures — don't block on them if automation is complex.

### 5. Produce Manifest

Output a manifest file listing all captures:

```markdown
# Screenshot Manifest

| File | Page | Viewport | Route/URL | State | Timestamp |
|------|------|----------|-----------|-------|-----------|
| home-desktop.png | Home | Desktop | / | Default | {timestamp} |
```

## Target Count

- **15–25 total screenshots** for a typical app
- Fewer for simple apps, more for complex ones
- Prioritize breadth (more pages) over depth (many states of one page)

## Rules

- **Wait for load completion.** Screenshots of loading spinners are useless.
- **Prefer representative over exhaustive.** 20 good screenshots > 100 screenshots of every route.
- **Note failures.** If a page doesn't render, log it in the manifest — don't silently skip.
- **Don't authenticate unless necessary.** If the app requires login, note it and capture what's accessible. If credentials are available, use them.
- **Full-page captures.** Capture the entire scrollable page, not just above-the-fold.

## Catch-Up Mode

When running incrementally:
1. Identify which pages/routes are affected by changed files
2. Re-capture only those pages at all three viewports
3. Keep existing screenshots for unchanged pages
4. Update the manifest
