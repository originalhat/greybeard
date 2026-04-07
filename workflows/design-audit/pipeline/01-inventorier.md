# Phase 1: Inventorier

- **Role:** Design Token Extractor
- **Model:** Sonnet
- **Input:** `sources/{repo}/` — frontend codebase
- **Output:** `output/{repo}/inventory.md` (following `templates/inventory.md`)

## Mission

Exhaustive static extraction of all design-related metrics from the codebase. Do not interpret or judge — collect raw data. The Analyzer (Phase 3) will evaluate.

## Process

### 1. Orient

Identify the frontend architecture:
- **Framework:** React, Vue, Angular, Svelte, vanilla, etc.
- **CSS approach:** CSS Modules, Tailwind, styled-components, SCSS, CSS-in-JS, vanilla CSS
- **Component library:** MUI, Chakra, Radix, Ant Design, custom, none
- **Token system:** CSS custom properties, Tailwind config, theme file, SCSS variables, none

Document these in the inventory header. The CSS approach determines where to look for values.

### 2. Extract Colors

Search all CSS, SCSS, styled-components, JSX inline styles, and Tailwind classes:
- Hex values (`#fff`, `#2563eb`)
- RGB/RGBA (`rgb(37, 99, 235)`, `rgba(0,0,0,0.5)`)
- HSL/HSLA
- CSS custom properties with color values
- Tailwind color classes (`text-blue-500`, `bg-gray-100`)
- Theme object color references

For each unique color value: record the value, format, whether it maps to a token, occurrence count, and all file:line locations.

Flag near-duplicates (colors within ~5% perceptual distance).

### 3. Extract Typography

Search for all type-related properties:
- `font-family`, `font-size`, `font-weight`, `line-height`, `letter-spacing`
- Tailwind type classes (`text-sm`, `font-bold`)
- Theme typography definitions

For each unique value: record property, value, token mapping, occurrence count, and locations.

### 4. Extract Spacing

Search for all spacing properties:
- `margin`, `padding`, `gap`, `top/right/bottom/left` (when used for spacing)
- Tailwind spacing classes (`p-4`, `mt-2`, `gap-6`)
- Theme spacing definitions

For each unique value: record value, token mapping, occurrence count, and locations.

### 5. Extract Layout

- All `@media` query breakpoint values
- `max-width` / `min-width` on containers
- `z-index` values with their purpose (infer from class/component name)
- Grid template definitions

### 6. Extract Components

- All exported UI components (Button, Card, Modal, Input, etc.)
- Their variant props and possible values
- Usage count across the codebase
- Identify duplicate patterns: similar markup structures appearing 3+ times

### 7. Map Token System

If a token system exists (CSS custom properties, theme file, Tailwind config):
- Document every defined token with its value and file:line
- Cross-reference: which tokens are actually used, which are orphaned
- This becomes the baseline the Analyzer compares against

## Output Format

Follow `templates/inventory.md` exactly. Every value must have a file:line reference. Include the Summary table at the bottom with aggregate counts.

## Rules

- **Every value needs a file:line reference.** No unattributed data.
- **Do not interpret.** Record `13px` as a font-size found, don't judge it as "wrong."
- **Be exhaustive.** Scan all CSS, SCSS, styled-components, inline styles, utility classes.
- **Flag the token system prominently.** The Analyzer depends on knowing what's intentional vs ad hoc.
- **Include both defined tokens and actual usage.** A token defined but never used is interesting. A value used but with no token is interesting.

## Catch-Up Mode

When running incrementally:
1. Receive list of changed files from the workflow orchestrator
2. Re-extract values from changed files only
3. Merge with existing inventory: update counts, add new values, remove values that no longer exist in changed files
4. Re-run near-duplicate detection on the full color set
