# File Upload

Detect unrestricted file upload, path traversal, and file handling vulnerabilities.

## What to Flag

### Unrestricted File Types
- No allowlist of permitted file extensions or MIME types
- Blocklist-only approach (easy to bypass with double extensions, null bytes)
- Client-side only validation (server accepts anything)

### Path Traversal
- User-controlled filenames used in file paths without sanitization
- `../` sequences not stripped from upload filenames
- User input in `File.join`, `Pathname.new`, `send_file`, `File.read`
- Zip extraction without path validation (zip slip)

### Storage Issues
- Uploaded files stored in publicly accessible directories (public/, static/)
- Original filenames preserved (information disclosure, collision, XSS via filename)
- No file size limits (denial of service)
- Missing virus/malware scanning on uploads

### Content Validation
- MIME type from Content-Type header trusted without verification
- No magic bytes / file signature validation
- SVG uploads without sanitization (can contain JavaScript)
- HTML file uploads that could be served as pages

## Patterns

```ruby
# BAD: Path traversal via filename
def upload
  filename = params[:file].original_filename
  File.open(Rails.root.join('uploads', filename), 'wb') { |f| f.write(params[:file].read) }
end

# GOOD: Sanitize filename, use random name
def upload
  ext = File.extname(params[:file].original_filename)
  raise unless ALLOWED_EXTENSIONS.include?(ext.downcase)
  filename = "#{SecureRandom.uuid}#{ext}"
  File.open(Rails.root.join('uploads', filename), 'wb') { |f| f.write(params[:file].read) }
end
```

```ruby
# BAD: User input in file path
def download
  send_file Rails.root.join('documents', params[:path])
end

# GOOD: Lookup by ID, not path
def download
  document = current_user.documents.find(params[:id])
  send_file document.file_path
end
```

## Severity

- **CRITICAL**: Path traversal allowing arbitrary file read/write, unrestricted upload to web-accessible directory
- **HIGH**: No file type validation, SVG/HTML uploads, zip slip
- **MEDIUM**: Blocklist-only validation, missing size limits
- **LOW**: Original filenames preserved, missing content-type verification

## False Positives to Avoid

- ActiveStorage/CarrierWave/Shrine with proper configuration (built-in protections)
- Uploads to cloud storage (S3) with randomized keys
- Admin-only upload endpoints with trusted users
- File operations on hardcoded/internal paths with no user input
