# Dependency Vulnerabilities

Detect known vulnerable dependencies, outdated packages, and supply chain risks in project manifests and lockfiles.

## What to Flag

### Known Vulnerabilities
- Gems with known CVEs in Gemfile/Gemfile.lock
- npm/yarn packages with known advisories in package.json/yarn.lock
- CocoaPods or Gradle dependencies with known vulnerabilities
- Pinned versions that are end-of-life or no longer receiving security patches

### Lockfile Issues
- Missing lockfiles (Gemfile.lock, yarn.lock, package-lock.json) — non-deterministic builds
- Lockfile not checked into version control
- Lockfile diverged from manifest (manual edits)

### Supply Chain Risks
- Dependencies with very few maintainers or downloads (potential typosquatting)
- Post-install scripts in npm packages (`preinstall`, `postinstall`)
- Git-sourced dependencies (no version pinning, mutable)
- Dependencies sourced from non-standard registries

### Version Pinning
- No version constraints (`gem 'rails'` without version)
- Overly loose constraints (`>= 0` or `*`)
- Major version ranges that may pull breaking security changes

## Patterns

```ruby
# BAD: No version constraint
gem 'devise'
gem 'rails', '>= 0'

# GOOD: Pinned to patch level
gem 'devise', '~> 4.9.3'
gem 'rails', '~> 7.1.3'
```

```json
// BAD: Wildcard version
{ "axios": "*" }
{ "lodash": ">=1.0.0" }

// GOOD: Pinned range
{ "axios": "^1.6.7" }
{ "lodash": "~4.17.21" }
```

```ruby
# BAD: Git source without ref pinning
gem 'custom_auth', git: 'https://github.com/org/custom_auth'

# GOOD: Pinned to specific ref
gem 'custom_auth', git: 'https://github.com/org/custom_auth', ref: 'abc1234'
```

## Severity

- **CRITICAL**: Dependencies with known RCE or auth bypass CVEs
- **HIGH**: Dependencies with known data exposure CVEs, missing lockfiles
- **MEDIUM**: End-of-life dependencies, overly loose version constraints
- **LOW**: Missing pinning on non-security-sensitive dependencies

## False Positives to Avoid

- Development-only dependencies (devDependencies, `:development` group) — lower risk
- Vulnerabilities that don't apply to the project's usage of the dependency
- Advisory has been disputed or withdrawn
- Dependency is vendored/forked with the vulnerability patched
