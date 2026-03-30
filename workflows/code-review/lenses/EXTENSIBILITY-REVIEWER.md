# Extensibility Reviewer

Detect designs that require modifying existing code to add new functionality (Open/Closed Principle violations).

## Core Principle

Code should be **open for extension** but **closed for modification**. Adding a new variant, type, or feature should not require changing existing, working code.

## What to Flag

### Hardcoded Type Switching
- Switch/case statements on type that must grow with new types
- If/else chains checking instanceof or type fields
- Conditionals that need a new branch for each variant

### Missing Extension Points
- No way to add behavior without modifying source
- Hardcoded lists of handlers/processors/validators
- Direct class instantiation instead of factories or DI
- No plugin/hook system where one would help

### Tight Coupling
- Concrete class dependencies instead of interfaces/protocols
- Direct imports of specific implementations
- Changes requiring updates to multiple unrelated files

### Configuration vs Code
- Values that should be configurable but are hardcoded
- Feature flags requiring code changes to add
- Hardcoded URLs, limits, or thresholds

## Patterns

```python
# BAD: Must modify this function for every new payment type
def process_payment(payment):
    if payment.type == 'credit_card':
        charge_credit_card(payment)
    elif payment.type == 'paypal':
        charge_paypal(payment)
    elif payment.type == 'crypto':  # Had to add this!
        charge_crypto(payment)

# GOOD: Register new processors without modifying existing code
PAYMENT_PROCESSORS = {
    'credit_card': CreditCardProcessor,
    'paypal': PayPalProcessor,
}

def process_payment(payment):
    processor = PAYMENT_PROCESSORS[payment.type]
    processor().charge(payment)

# Adding new type: just register it
PAYMENT_PROCESSORS['crypto'] = CryptoProcessor
```

```ruby
# BAD: Hardcoded notification channels
def notify_user(user, message)
  send_email(user, message)
  send_sms(user, message) if user.phone
  send_slack(user, message) if user.slack_id
  # Adding push notifications means changing this method
end

# GOOD: Extensible notifiers
def notify_user(user, message)
  NotificationService.notifiers_for(user).each do |notifier|
    notifier.send(user, message)
  end
end
```

```typescript
// BAD: Must modify for new export formats
function exportReport(data: Data, format: string) {
  if (format === 'pdf') return generatePdf(data)
  if (format === 'csv') return generateCsv(data)
  if (format === 'xlsx') return generateXlsx(data)  // Added later
}

// GOOD: Pluggable exporters
const exporters: Record<string, Exporter> = {
  pdf: new PdfExporter(),
  csv: new CsvExporter(),
}

function exportReport(data: Data, format: string) {
  return exporters[format].export(data)
}
```

## The Extension Test

Ask: "If we need to add a new [type/variant/format/handler], how many files change?"

- **0-1 files**: Well-designed, just add the new thing
- **2-3 files**: Acceptable, some registration needed
- **4+ files**: Likely an extensibility problem

## When NOT to Flag

- Simple code that's unlikely to need extension
- Internal utilities with fixed, known variants
- Early-stage code where patterns aren't yet clear
- Premature abstraction that adds complexity without benefit

## Severity

- **HIGH**: Core domain concept that's clearly growing (payment types, export formats)
- **MEDIUM**: Could benefit from extension points but manageable
- **LOW**: Minor rigidity, unlikely to cause problems

## False Positives to Avoid

- Switch statements with truly fixed, exhaustive cases
- Simple conditionals that won't grow
- Over-engineering for hypothetical future needs
- Small apps where YAGNI applies
