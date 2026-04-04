# Security Patterns

Reusable security patterns for all skill scripts. Follow these in every script
that handles user input, credentials, or external data.

## Input Sanitization

Always sanitize user input before using in commands, URLs, or API calls.

```bash
# Sanitize user input - remove dangerous characters
sanitize_input() {
    local input="$1"
    # Remove shell metacharacters and command injection attempts
    echo "$input" | sed 's/[;&|`$(){}[\]<>\\]//g' | tr -d '\n\r'
}

# Usage
user_query=$(sanitize_input "$1")
```

## Command Injection Prevention

Never directly interpolate user input into shell commands or URLs.

```bash
# DANGEROUS - Command injection vulnerability
curl "https://api.example.com/search?q=$user_input"

# SAFE - Properly escaped and quoted
query=$(printf '%s' "$user_input" | jq -sRr @uri)
curl "https://api.example.com/search?q=${query}"
```

## URL Encoding

Always URL-encode user input when building API requests.

```bash
# URL encode function
url_encode() {
    local string="$1"
    printf '%s' "$string" | jq -sRr @uri
}

# Usage
search_term=$(url_encode "user's search & query")
curl "https://api.example.com/search?q=${search_term}"
```

## SQL Injection Prevention (Python)

Use parameterized queries, NEVER string concatenation.

```python
# DANGEROUS - SQL injection vulnerability
cursor.execute(f"SELECT * FROM users WHERE username = '{username}'")

# SAFE - Parameterized query
cursor.execute("SELECT * FROM users WHERE username = %s", (username,))
```

## API Key Protection

Never log, print, or expose credentials.

```bash
# DANGEROUS - Logs API key
echo "Using API key: $API_KEY"
curl -H "Authorization: Bearer $API_KEY" https://api.example.com

# SAFE - No credential exposure
if [ -z "$API_KEY" ]; then
    log_error "API_KEY not set"
    exit 1
fi
curl -H "Authorization: Bearer $API_KEY" https://api.example.com 2>&1 | grep -v "Authorization"
```

## Path Traversal Prevention

Validate file paths to prevent directory traversal attacks.

```bash
# Validate file path is within allowed directory
validate_path() {
    local file_path="$1"
    local base_dir="$2"

    # Resolve to absolute path
    local abs_path=$(realpath -m "$file_path" 2>/dev/null)
    local abs_base=$(realpath "$base_dir")

    # Check if path starts with base directory
    if [[ "$abs_path" != "$abs_base"* ]]; then
        log_error "Invalid path: $file_path (outside base directory)"
        return 1
    fi

    echo "$abs_path"
}

# Usage
safe_path=$(validate_path "$user_file" "/allowed/directory") || exit 1
```

## JSON Response Parsing

Always validate JSON structure before parsing.

```bash
# Validate JSON response
parse_json_safely() {
    local json="$1"
    local key="$2"

    # Check if valid JSON
    if ! echo "$json" | jq empty 2>/dev/null; then
        log_error "Invalid JSON response"
        return 1
    fi

    # Extract value
    echo "$json" | jq -r ".$key // empty"
}

# Usage
response=$(curl -s https://api.example.com/data)
value=$(parse_json_safely "$response" "data.field") || exit 1
```
