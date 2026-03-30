# Separation of Concerns Reviewer

Detect misplaced business logic and layer responsibility violations that hurt testability and reusability.

## Layer Responsibilities

| Layer | Should Do | Should NOT Do |
|-------|-----------|---------------|
| Controller/Handler | Route requests, parse input, return responses | Business rules, complex conditionals, DB queries |
| Service/Use Case | Orchestrate multi-step operations | HTTP concerns, presentation, direct DB access |
| Model/Domain | Business rules, validations, state transitions | HTTP, rendering, external API details |
| View/Serializer | Format data for presentation | Business logic, DB queries, mutations |

## What to Flag

### Fat Controllers/Handlers
- Business logic in controller actions
- Complex conditionals determining behavior
- Data transformations beyond simple mapping
- Multiple model operations without a service
- Duplicated logic across controllers

### Anemic Models
- Models with only getters/setters, no behavior
- Business rules living outside the domain objects
- Validation logic in controllers instead of models
- State transitions managed externally

### Logic in Wrong Layer
- Database queries in views/serializers
- HTTP/request details leaking into services
- Presentation concerns in domain models
- Business rules in background job classes (should call domain)

### Duplication Signals
- Same conditional in multiple controllers
- Copy-pasted validation logic
- Business rule repeated in API and background job

## Patterns

```ruby
# BAD: Fat controller with business logic
class OrdersController
  def create
    if params[:total] > 1000 && !current_user.verified?
      return render json: { error: "Unverified users limited to $1000" }
    end
    if inventory.available?(params[:items])
      order = Order.create!(params)
      order.items.each { |i| inventory.decrement(i) }
      UserMailer.order_confirmation(order).deliver_later
    end
  end
end

# GOOD: Thin controller, logic in domain
class OrdersController
  def create
    result = OrderService.place_order(current_user, order_params)
    if result.success?
      render json: result.order
    else
      render json: { error: result.error }, status: :unprocessable_entity
    end
  end
end
```

```python
# BAD: Business logic in API handler
@app.route('/api/approve', methods=['POST'])
def approve_request():
    request = Request.get(id)
    if request.amount > 10000:
        if not current_user.is_senior_approver:
            return {"error": "Requires senior approval"}, 403
    request.status = 'approved'
    request.approved_by = current_user.id
    request.approved_at = datetime.now()
    db.commit()
    send_approval_email(request)

# GOOD: Handler calls domain
@app.route('/api/approve', methods=['POST'])
def approve_request():
    result = approval_service.approve(request_id, current_user)
    return result.to_response()
```

## The Reusability Test

Ask: "If I needed this logic in a different context (CLI, background job, different endpoint), would I have to copy it?"

If yes → logic is in the wrong place.

## Severity

- **HIGH**: Business logic in controllers that's duplicated or hard to test
- **MEDIUM**: Logic in slightly wrong layer but still testable
- **LOW**: Minor organizational issues, stylistic concerns

## False Positives to Avoid

- Simple CRUD controllers (thin by nature)
- Appropriate orchestration in controllers (calling services is fine)
- Framework conventions that put some logic in controllers
- Small apps where layering adds unnecessary complexity
