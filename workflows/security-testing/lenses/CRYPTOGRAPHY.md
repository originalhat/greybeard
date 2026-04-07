# Cryptography

Detect weak cryptographic practices, hardcoded secrets, and key management issues.

## What to Flag

### Hardcoded Secrets
- API keys, passwords, tokens in source code
- `secret_key_base`, database passwords in checked-in config files
- Private keys or certificates in the repository
- Base64-encoded secrets (still plaintext)

### Weak Hashing
- MD5 or SHA1 for password hashing
- Hashing without salt
- Custom hashing implementations instead of bcrypt/scrypt/argon2
- Low bcrypt cost factor (<10)

### Weak Encryption
- DES, 3DES, RC4, Blowfish for sensitive data
- RSA with key size <2048 bits
- ECB mode for block ciphers
- Hardcoded initialization vectors (IVs)
- `attr_encrypted` with weak algorithm or static key

### Insufficient Randomness
- `Math.random()`, `rand()`, `Random.new` for security-sensitive values (tokens, keys, IDs)
- Sequential or timestamp-based tokens
- Predictable session IDs or reset tokens

### Key Management
- Encryption keys in source code or version control
- Keys in environment variables without rotation mechanism
- Shared keys across environments (dev key = prod key)
- Missing key rotation capability

## Patterns

```ruby
# BAD: Hardcoded secret
SECRET_KEY = "my-secret-key-12345"
config.secret_key_base = "abc123..."

# GOOD: Environment variable
config.secret_key_base = ENV.fetch("SECRET_KEY_BASE")
```

```ruby
# BAD: MD5 for password
Digest::MD5.hexdigest(password)

# GOOD: bcrypt
BCrypt::Password.create(password)
```

```ruby
# BAD: Predictable token
token = Time.now.to_i.to_s(36)
token = SecureRandom.random_number(999999).to_s

# GOOD: Cryptographically secure token
token = SecureRandom.urlsafe_base64(32)
```

```javascript
// BAD: Math.random for token
const token = Math.random().toString(36)

// GOOD: Crypto API
const token = crypto.randomBytes(32).toString('hex')
```

## Severity

- **CRITICAL**: Hardcoded production secrets, private keys in repo
- **HIGH**: Weak password hashing, predictable security tokens
- **MEDIUM**: Weak encryption algorithms, insufficient randomness for non-auth purposes
- **LOW**: Low bcrypt cost, missing key rotation documentation

## False Positives to Avoid

- Example/placeholder values in documentation or comments
- Test fixtures with fake credentials clearly marked
- Development-only configuration (`.env.development`, `config/environments/development.rb`)
- Hash functions used for non-security purposes (checksums, cache keys, deduplication)
