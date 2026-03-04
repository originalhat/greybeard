This is a tool for doing in-depth, multi-stage, multi-modal code reviews.

The typical flow is:

1. Provide branch to review
2. Check this branch out under appropriate repo in repos dir
3. Compare diff against origin/main
4. Evaluate in parallel using modules in modules dir
5. Evaluate in parallel against specifics
6. Create a final report with a concise high level summary of issues
7. Fact-check each of these issues in parallel in the repo to ensure they're contextuall correct and truly a problem;
8. If there's any remaining failing issues, do a x-repo analysis (if that would help provider clarity); cf repos/CLAUDE.md
9. Finally, provide a concise summary of what was checked with a PASS/FAIL per module; describe the issue on anything that's failing with location and potential fix

Other things:
- repos aren't currently set up to be working environements so console, tests, etc may not work

### Modules

- Focus on single area
- Are generalized (no repo-specific patterns)
- Range from 45-96 lines (all under 100)
- Can be quickly skimmed

