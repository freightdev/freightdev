## Usage Examples:

### Basic Usage:

```bash
# Test with your original structure
./scaffold simple.tree ./output --dry

# Create with warnings for suspicious patterns  
./scaffold malicious.tree ./danger-zone

# Test deep nesting with custom depth limit
./scaffold deep.md ./deep-test --max-depth 15

# Force creation without prompts
./scaffold enterprise.md ./my-app --force

# Preview mixed format parsing
./scaffold mixed.txt ./preview --preview --debug
```

### Advanced Usage:

```bash
# Test Unicode support
./scaffold unicode.tree ./unicode-test --debug

# Maximum depth with dry run
./scaffold deep.md ./depth-test --dry --max-depth 25

# Force creation of suspicious structure
./scaffold malicious.tree ./forced --force --debug
```

## Usage Notes:

The script will detect and warn about:

 * Command substitution patterns: `$(cmd)`, `\cmd`

 * Directory traversal: `../../../`

 * Absolute paths: `/root/`

 * Shell operators: `|`, `&`, `;`, `<`, `>`

 * Glob patterns: `*`, `?`, `{`, `}`

 * Variable substitution: `${VAR}`

 * Special characters and potential exploits
