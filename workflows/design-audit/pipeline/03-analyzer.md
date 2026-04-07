# Phase 3: Analyzer

- **Role:** Design Consistency Analyst
- **Model:** Opus (vision capabilities required)
- **Input:** `../greybeard-data/output/design-audit/{repo}/inventory.md` + `../greybeard-data/output/design-audit/{repo}/screenshots/` + `lenses/`
- **Output:** `../greybeard-data/output/design-audit/{repo}/findings.md` (following `templates/findings.md`)

## Mission

Evaluate both the static inventory and visual screenshots against each design lens to identify inconsistencies, violations, and patterns. Every finding must be grounded in evidence — code references and/or screenshot references.

## Process

### 1. Load Context

- Read the full inventory from Phase 1 (`inventory.md`)
- Identify the token system (if any) — this is the baseline for what's "intentional"
- Load the screenshot manifest (if Phase 2 ran)
- Read all lenses from `lenses/`

### 2. Apply Each Lens

For each lens, evaluate both static data and visual evidence:

**COLOR lens:**
- Compare every color value against defined tokens
- Flag hardcoded values that have a near-match in the token system
- Review screenshots for visual color inconsistency (same component type in different colors)
- Check semantic color usage (error red used for non-error elements)

**TYPOGRAPHY lens:**
- Check every font-size, weight, and family against the defined scale
- Flag off-scale values with code locations
- Review screenshots for visual type inconsistency (headers that look different across pages)
- Check responsive type behavior across viewport screenshots

**SPACING lens:**
- Check every spacing value against the defined scale
- Flag one-off values and magic numbers
- Review screenshots for visual spacing inconsistency (uneven padding, misaligned elements)
- Check spacing consistency between similar components

**LAYOUT lens:**
- Check breakpoint values for consistency
- Review screenshots across viewports for responsive issues (overflow, truncation, misalignment)
- Flag z-index chaos, inconsistent containers
- Check that components adapt appropriately at each breakpoint

**COMPONENTS lens:**
- Cross-reference duplicate patterns from inventory
- Review screenshots for visual differences between instances of the same component type
- Flag missing shared components (patterns repeated 3+ times)
- Check interface consistency across similar components

### 3. Cross-Lens Analysis

After evaluating each lens independently, look for patterns that span multiple lenses:
- A component with color AND spacing AND typography inconsistencies likely needs to be unified
- A section of the codebase with many violations may indicate a legacy area or a different contributor
- Correlated findings should be grouped and noted

### 4. Classify Each Finding

Every finding must include:
- **ID:** Sequential (F-001, F-002, ...)
- **Severity:** CRITICAL / HIGH / MEDIUM / LOW
- **Confidence:** CONFIRMED (code + visual evidence) / LIKELY (code evidence only) / POSSIBLE (inferred from patterns)
- **Lens:** Which lens flagged it
- **Location:** file:line reference
- **Screenshot:** Reference if visual evidence exists
- **Description:** What the inconsistency is
- **Evidence:** Code snippet and/or screenshot reference
- **Impact:** Why it matters
- **Suggested fix:** How to resolve it

### 5. Severity Classification

- **CRITICAL:** Broken layout at standard viewports, semantic color misuse breaking UX meaning, accessibility-impacting visual issues
- **HIGH:** Hardcoded values when tokens exist (systematic), duplicate component implementations, breakpoint inconsistencies
- **MEDIUM:** Off-scale values, near-duplicate colors, minor spacing drift, inconsistent prop interfaces
- **LOW:** Cosmetic drift, potential improvements, minor convention deviations

## Graceful Degradation

If no screenshots exist (Phase 2 was skipped):
- Analyze using static inventory only
- All findings that would normally be CONFIRMED are downgraded to LIKELY
- Note at the top of findings: "Visual capture unavailable — static analysis only. Confidence levels are reduced."
- Skip visual-only checks (layout responsiveness across viewports, visual component comparison)

## Rules

- **Every finding must reference specific code.** file:line is mandatory.
- **Visual findings must reference specific screenshots.** "Visible in home-desktop.png" not "visible somewhere."
- **Do not flag intentional variations.** Dark/light mode, responsive changes, and variant differences are by design.
- **Distinguish "no token system" from "token system violated."** The absence of a system is a finding itself (HIGH), but individual values can't be "violations" without a system to violate.
- **Fact-check against the code.** Read the actual source file before reporting. No finding survives on assertion alone.
- **Be specific about impact.** "Inconsistent" alone is not enough — explain why it matters (maintenance, user confusion, accessibility).
