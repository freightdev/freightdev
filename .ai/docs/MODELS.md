# GTX - The Manager (general reasoning, NOT coder)

ollama pull qwen2.5:32b-instruct-q4_K_M

# i9 - Primary Worker (coder)

ollama pull qwen2.5-coder:14b-instruct-q5_K_M

# NPU - Secondary Worker (coder)

ollama pull qwen2.5-coder:7b-instruct-q4_K_M

# Smol - Utility (coder)

ollama pull qwen2.5-coder:1.5b-instruct-q4_K_M

```

## Why This Works

The **general Qwen2.5** (not coder) is trained on:
- Mathematical reasoning
- Logical decomposition
- Abstract planning
- Meta-cognition
- Prompt engineering patterns

The **coder variants** are trained on:
- Syntax completion
- Code patterns
- Implementation details
- Bug fixing

You need the first one to manage, the second ones to execute.

Your orchestrator will generate prompts like:
```

"Implement a REST API endpoint with the following spec:

- Route: POST /api/users
- Validation: email format, password min 8 chars
- Database: PostgreSQL with users table
- Return: 201 with user object or 400 with errors
  Use the express-validator library and follow our error handling template."
