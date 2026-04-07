# Design Inventory: {repo}

- **Date:** {date}
- **Agent:** Inventorier (Sonnet)
- **Repo SHA:** {sha}
- **Framework:** {framework}
- **CSS Approach:** {css_approach} (e.g., CSS Modules, Tailwind, styled-components, SCSS)
- **Component Library:** {library or "None"}

## Token System

{Description of the token system if one exists. Where tokens are defined (file paths), how they are consumed (CSS vars, Tailwind config, theme object), and overall organization. If no formal token system exists, state: "No formal token system found. Colors, spacing, and typography values are defined inline or in scattered files."}

## Colors

### Defined Tokens

| Token/Variable | Value | Defined In |
|---------------|-------|------------|
| {--color-primary} | {#2563eb} | {src/styles/tokens.css:12} |

### All Color Values Found

| Value | Format | Token? | Occurrences | Locations |
|-------|--------|--------|-------------|-----------|
| {#2563eb} | {hex} | {Yes: --color-primary} | {14} | {src/components/Button.tsx:8, ...} |
| {#333333} | {hex} | {No} | {7} | {src/pages/Home.tsx:22, ...} |

### Near-Duplicates

| Color A | Color B | Distance | Locations |
|---------|---------|----------|-----------|
| {#333} | {#343434} | {~1%} | {A: header.css:5, B: card.css:12} |

## Typography

### Defined Scale

| Token/Variable | Size | Weight | Line Height | Defined In |
|---------------|------|--------|-------------|------------|
| {--text-sm} | {14px} | {400} | {1.5} | {tokens.css:20} |

### All Type Values Found

| Property | Value | Token? | Occurrences | Locations |
|----------|-------|--------|-------------|-----------|
| {font-size} | {14px} | {Yes: --text-sm} | {22} | {Button.tsx:8, ...} |
| {font-size} | {13px} | {No} | {3} | {Tooltip.tsx:5, ...} |

### Font Families

| Family | Role | Occurrences | Defined In |
|--------|------|-------------|------------|
| {Inter} | {Primary} | {45} | {tokens.css:2} |

## Spacing

### Defined Scale

| Token/Variable | Value | Defined In |
|---------------|-------|------------|
| {--space-1} | {4px} | {tokens.css:30} |

### All Spacing Values Found

| Value | Token? | Occurrences | Locations |
|-------|--------|-------------|-----------|
| {4px} | {Yes: --space-1} | {35} | {Card.tsx:12, ...} |
| {7px} | {No} | {2} | {Badge.tsx:8, ...} |

## Layout

### Breakpoints

| Name | Value | Occurrences | Defined In |
|------|-------|-------------|------------|
| {md} | {768px} | {12} | {tailwind.config.js:8} |

### Containers

| Max Width | Occurrences | Locations |
|-----------|-------------|-----------|
| {1280px} | {4} | {Layout.tsx:5, ...} |

### Z-Index Values

| Value | Purpose | Location |
|-------|---------|----------|
| {50} | {Modal overlay} | {Modal.tsx:15} |

## Components

### UI Components Found

| Component | Variants | Occurrences | Location |
|-----------|----------|-------------|----------|
| {Button} | {primary, secondary, ghost} | {34} | {src/components/Button.tsx} |

### Duplicate Patterns

| Pattern | Implementations | Locations |
|---------|----------------|-----------|
| {Card layout} | {3} | {CardA.tsx, CardB.tsx, InlineCard in Dashboard.tsx} |

## Summary

| Metric | Count |
|--------|-------|
| Unique colors | {N} |
| Colors with tokens | {N} |
| Colors without tokens | {N} |
| Font sizes in scale | {N} |
| Font sizes off-scale | {N} |
| Spacing values in scale | {N} |
| Spacing values off-scale | {N} |
| Breakpoints defined | {N} |
| Z-index values | {N} |
| Shared components | {N} |
| Duplicate patterns | {N} |
