#!/bin/bash
#
# Universal Project Generator - Setup Script
# Automatically creates the complete modular project structure
#

set -e  # Exit on error

PROJECT_NAME="codriver"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Universal Project Generator - Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# ============================================================================
# STEP 1: Create Directory Structure
# ============================================================================
echo -e "${GREEN}Step 1:${NC} Creating directory structure..."

mkdir -p ${PROJECT_NAME}/{src/{core,clients,validators,formatters,generators,templates/{go,python,dart,common},workflow,agents,utils,cli},tests/{unit,integration,fixtures},config/{examples,presets},scripts,docs,generated,.checkpoint}

cd ${PROJECT_NAME}

echo -e "  ${GREEN}✓${NC} Directories created"

# ============================================================================
# STEP 2: Create __init__.py Files
# ============================================================================
echo -e "${GREEN}Step 2:${NC} Creating __init__.py files..."

find src -type d -exec touch {}/__init__.py \;
find tests -type d -exec touch {}/__init__.py \;

echo -e "  ${GREEN}✓${NC} __init__.py files created"

# ============================================================================
# STEP 3: Create requirements.txt
# ============================================================================
echo -e "${GREEN}Step 3:${NC} Creating requirements.txt..."

cat > requirements.txt << 'EOF'
# Core dependencies
langgraph>=0.0.20
langchain>=0.1.0
langchain-community>=0.0.10
pyyaml>=6.0

# LLM clients
ollama>=0.1.0

# Utilities
jinja2>=3.1.0
tqdm>=4.66.0

# Development
pytest>=7.4.0
pytest-cov>=4.1.0
black>=23.0.0
mypy>=1.5.0
EOF

echo -e "  ${GREEN}✓${NC} requirements.txt created"

# ============================================================================
# STEP 4: Create setup.py
# ============================================================================
echo -e "${GREEN}Step 4:${NC} Creating setup.py..."

cat > setup.py << 'EOF'
from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="universal-project-generator",
    version="1.0.0",
    author="Your Name",
    description="Universal project generator with 3-agent Ollama cluster",
    long_description=long_description,
    long_description_content_type="text/markdown",
    packages=find_packages(),
    install_requires=[
        "langgraph>=0.0.20",
        "langchain>=0.1.0",
        "langchain-community>=0.0.10",
        "ollama>=0.1.0",
        "pyyaml>=6.0",
        "jinja2>=3.1.0",
        "tqdm>=4.66.0",
    ],
    entry_points={
        'console_scripts': [
            'project-gen=src.cli.main:main',
        ],
    },
    python_requires=">=3.10",
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
)
EOF

echo -e "  ${GREEN}✓${NC} setup.py created"

# ============================================================================
# STEP 5: Create .gitignore
# ============================================================================
echo -e "${GREEN}Step 5:${NC} Creating .gitignore..."

cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual Environment
venv/
env/
ENV/
.venv

# IDE
.vscode/
.idea/
*.swp
*.swo
*.sublime-project
*.sublime-workspace

# Generated files
generated/
.checkpoint/
*.log

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/

# OS
.DS_Store
Thumbs.db
EOF

echo -e "  ${GREEN}✓${NC} .gitignore created"

# ============================================================================
# STEP 6: Create pyproject.toml
# ============================================================================
echo -e "${GREEN}Step 6:${NC} Creating pyproject.toml..."

cat > pyproject.toml << 'EOF'
[build-system]
requires = ["setuptools>=45", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "universal-project-generator"
version = "1.0.0"
description = "Universal project generator with 3-agent Ollama cluster"
requires-python = ">=3.10"

[tool.black]
line-length = 100
target-version = ['py310']
include = '\.pyi?$'

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = "-v --cov=src --cov-report=html"

[tool.mypy]
python_version = "3.10"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
EOF

echo -e "  ${GREEN}✓${NC} pyproject.toml created"

# ============================================================================
# STEP 7: Create README.md
# ============================================================================
echo -e "${GREEN}Step 7:${NC} Creating README.md..."

cat > README.md << 'EOF'
# Universal Project Generator

AI-powered project generator using a 3-agent Ollama cluster to create production-ready code.

## Features

- 🏗️  **Architecture Planning** - Intelligent project structure design
- 💻 **Code Generation** - Complete, working implementations
- 🔍 **Code Review** - Automated quality checks
- 📝 **Documentation** - Auto-generated README, API docs
- 🐳 **Deployment** - Docker, docker-compose ready
- ✅ **Testing** - Test file generation
- 🔄 **Multi-language** - Go, Python, Dart/Flutter support

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Generate example configs
python -m src.cli.main examples

# Generate a project
python -m src.cli.main generate \
  --project config/examples/go_microservice.yaml \
  --cluster config/cluster_config.yaml
```

## Installation

```bash
# Install in development mode
pip install -e .

# Use CLI command
project-gen generate --project myproject.yaml
```

## Configuration

### Cluster Configuration (`config/cluster_config.yaml`)

```yaml
architect:
  role: architect
  model: qwen2.5-coder:7b
  base_url: http://localhost:11434

coder:
  role: coder
  model: qwen2.5-coder:7b
  base_url: http://localhost:11434

reviewer:
  role: reviewer
  model: qwen2.5-coder:7b
  base_url: http://localhost:11434
```

### Project Schema (`myproject.yaml`)

```yaml
project_name: my-service
project_type: microservice
description: My awesome service

languages:
  - go

frameworks:
  - chi

databases:
  - redis

architecture_style: clean_architecture
```

## Documentation

- [Installation Guide](docs/installation.md)
- [Configuration](docs/configuration.md)
- [Architecture](docs/architecture.md)
- [Examples](docs/examples/)

## License

MIT
EOF

echo -e "  ${GREEN}✓${NC} README.md created"

# ============================================================================
# STEP 8: Create Example Cluster Config
# ============================================================================
echo -e "${GREEN}Step 8:${NC} Creating example configurations..."

mkdir -p config/examples

cat > config/cluster_config.yaml << 'EOF'
architect:
  role: architect
  model: qwen2.5-coder:7b
  base_url: http://localhost:11434
  temperature: 0.7
  timeout: 300
  max_retries: 3

coder:
  role: coder
  model: qwen2.5-coder:7b
  base_url: http://localhost:11434
  temperature: 0.7
  timeout: 300
  max_retries: 3

reviewer:
  role: reviewer
  model: qwen2.5-coder:7b
  base_url: http://localhost:11434
  temperature: 0.7
  timeout: 300
  max_retries: 3

output_dir: ./generated
logging_level: INFO
save_intermediate: true
validate_syntax: true
format_code: true
EOF

# ============================================================================
# STEP 9: Create Example Project Schemas
# ============================================================================

cat > config/examples/go_microservice.yaml << 'EOF'
project_name: auth-service
project_type: microservice
description: Authentication service with JWT and session management

languages:
  - go

frameworks:
  - chi

databases:
  - surrealdb
  - redis

architecture_style: clean_architecture

design_patterns:
  - repository
  - dependency_injection
  - factory

features:
  - login
  - register
  - refresh_token
  - logout
  - session_management

api_endpoints:
  - method: POST
    path: /api/v1/auth/register
    description: Register new user
    request_body:
      email: string
      password: string
    response:
      user_id: string
      access_token: string
  
  - method: POST
    path: /api/v1/auth/login
    description: Login user
    request_body:
      email: string
      password: string
    response:
      access_token: string
      refresh_token: string

authentication: true
authorization: true
logging: true
testing: true
documentation: true

containerization: docker
orchestration: docker-compose
EOF

cat > config/examples/python_api.yaml << 'EOF'
project_name: payment-api
project_type: rest_api
description: Payment processing API with Stripe integration

languages:
  - python

frameworks:
  - fastapi

databases:
  - postgres
  - redis

external_services:
  - stripe
  - sendgrid

architecture_style: layered

design_patterns:
  - repository
  - strategy
  - observer

features:
  - payment_processing
  - webhook_handling
  - invoice_generation
  - refunds

api_endpoints:
  - method: POST
    path: /api/v1/payments
    description: Process payment
  - method: POST
    path: /api/v1/refunds
    description: Process refund
  - method: POST
    path: /webhooks/stripe
    description: Handle Stripe webhooks

authentication: true
authorization: true
caching: true
logging: true
testing: true
documentation: true

containerization: docker
orchestration: docker-compose
EOF

cat > config/examples/flutter_app.yaml << 'EOF'
project_name: dashboard-app
project_type: mobile_app
description: Real-time dashboard with charts and analytics

languages:
  - dart

frameworks:
  - flutter
  - bloc

external_services:
  - rest_api
  - websocket

architecture_style: bloc_pattern

design_patterns:
  - repository
  - bloc
  - observer

features:
  - dashboard
  - real_time_charts
  - user_profile
  - settings
  - notifications

authentication: true
real_time: true
logging: true
testing: true
documentation: true
EOF

echo -e "  ${GREEN}✓${NC} Example configurations created"

# ============================================================================
# STEP 10: Create Core Files
# ============================================================================
echo -e "${GREEN}Step 9:${NC} Creating core module files..."

# src/core/constants.py
cat > src/core/constants.py << 'EOF'
"""Project constants and enums"""
from enum import Enum

class ProjectType(Enum):
    MICROSERVICE = "microservice"
    REST_API = "rest_api"
    MOBILE_APP = "mobile_app"
    WEB_APP = "web_app"
    CLI_TOOL = "cli_tool"
    LIBRARY = "library"

class ArchitectureStyle(Enum):
    CLEAN_ARCHITECTURE = "clean_architecture"
    HEXAGONAL = "hexagonal"
    LAYERED = "layered"
    MVC = "mvc"
    MVVM = "mvvm"
    BLOC = "bloc_pattern"

SUPPORTED_LANGUAGES = {'go', 'python', 'dart', 'javascript', 'typescript', 'rust', 'java'}
SUPPORTED_DATABASES = {'postgres', 'mysql', 'mongodb', 'redis', 'surrealdb', 'sqlite'}
SUPPORTED_FRAMEWORKS = {
    'go': {'chi', 'gin', 'echo', 'fiber'},
    'python': {'fastapi', 'flask', 'django'},
    'dart': {'flutter'},
    'javascript': {'express', 'react', 'vue', 'nextjs'},
    'typescript': {'nestjs', 'express', 'react', 'nextjs'}
}
EOF

# src/utils/logger.py
cat > src/utils/logger.py << 'EOF'
"""Logging configuration"""
import logging
from datetime import datetime
from pathlib import Path

def setup_logging(level: str = "INFO") -> logging.Logger:
    """Setup logging with console and file handlers"""
    logger = logging.getLogger("ProjectGenerator")
    logger.setLevel(getattr(logging, level))
    logger.handlers.clear()
    
    # Console handler
    console = logging.StreamHandler()
    console.setLevel(getattr(logging, level))
    console.setFormatter(logging.Formatter(
        '%(asctime)s [%(levelname)s] %(message)s',
        datefmt='%H:%M:%S'
    ))
    logger.addHandler(console)
    
    # File handler
    log_file = f"generation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
    file_handler = logging.FileHandler(log_file)
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s'
    ))
    logger.addHandler(file_handler)
    
    return logger
EOF

# src/utils/json_parser.py
cat > src/utils/json_parser.py << 'EOF'
"""Robust JSON parsing from LLM responses"""
import json
import re
from typing import Optional, Dict, Any

def parse_json_robust(response: str) -> Optional[Dict[str, Any]]:
    """Parse JSON from LLM response with multiple fallback strategies"""
    
    # Strategy 1: Remove markdown code blocks
    if "```" in response:
        patterns = [
            r'```json\s*(.*?)\s*```',
            r'```\s*(.*?)\s*```',
        ]
        for pattern in patterns:
            match = re.search(pattern, response, re.DOTALL)
            if match:
                response = match.group(1)
                break
    
    # Strategy 2: Find JSON object boundaries
    try:
        start = response.find('{')
        end = response.rfind('}') + 1
        if start != -1 and end > start:
            json_str = response[start:end]
            return json.loads(json_str)
    except:
        pass
    
    # Strategy 3: Try parsing entire response
    try:
        return json.loads(response.strip())
    except:
        pass
    
    return None
EOF

echo -e "  ${GREEN}✓${NC} Core files created"

# ============================================================================
# STEP 11: Create Virtual Environment
# ============================================================================
echo -e "${GREEN}Step 10:${NC} Setting up virtual environment..."

if command -v python3 &> /dev/null; then
    python3 -m venv venv
    echo -e "  ${GREEN}✓${NC} Virtual environment created"
    echo -e "  ${YELLOW}ℹ${NC}  Activate with: source venv/bin/activate"
else
    echo -e "  ${YELLOW}⚠${NC}  Python3 not found, skipping venv creation"
fi

# ============================================================================
# STEP 12: Create Helper Scripts
# ============================================================================
echo -e "${GREEN}Step 11:${NC} Creating helper scripts..."

cat > scripts/install.sh << 'EOF'
#!/bin/bash
# Install dependencies

echo "Installing dependencies..."

if [ -d "venv" ]; then
    source venv/bin/activate
fi

pip install -r requirements.txt
pip install -e .

echo "✓ Installation complete"
EOF

cat > scripts/test.sh << 'EOF'
#!/bin/bash
# Run tests

echo "Running tests..."

if [ -d "venv" ]; then
    source venv/bin/activate
fi

pytest tests/ -v --cov=src --cov-report=html

echo "✓ Tests complete"
echo "Coverage report: htmlcov/index.html"
EOF

cat > scripts/format.sh << 'EOF'
#!/bin/bash
# Format code

echo "Formatting code..."

if [ -d "venv" ]; then
    source venv/bin/activate
fi

black src/ tests/
echo "✓ Formatting complete"
EOF

chmod +x scripts/*.sh

echo -e "  ${GREEN}✓${NC} Helper scripts created"

# ============================================================================
# STEP 13: Create Test Files
# ============================================================================
echo -e "${GREEN}Step 12:${NC} Creating test structure..."

cat > tests/conftest.py << 'EOF'
"""Pytest configuration and fixtures"""
import pytest
from pathlib import Path

@pytest.fixture
def temp_output_dir(tmp_path):
    """Temporary output directory for tests"""
    output_dir = tmp_path / "generated"
    output_dir.mkdir()
    return output_dir

@pytest.fixture
def sample_project_schema():
    """Sample project schema for testing"""
    from src.core.schemas import ProjectSchema
    return ProjectSchema(
        project_name="test-project",
        project_type="microservice",
        description="Test project",
        languages=["go"],
        frameworks=["chi"],
        architecture_style="clean_architecture"
    )
EOF

cat > tests/unit/test_schemas.py << 'EOF'
"""Test core schemas"""
import pytest
from src.core.schemas import ProjectSchema, FileTemplate

def test_file_template_creation():
    template = FileTemplate(
        path="main.go",
        purpose="entry point",
        file_type="main",
        language="go"
    )
    assert template.path == "main.go"
    assert template.priority == 5

def test_project_schema_defaults(sample_project_schema):
    assert sample_project_schema.authentication == False
    assert sample_project_schema.testing == True
    assert sample_project_schema.logging == True
EOF

echo -e "  ${GREEN}✓${NC} Test files created"

# ============================================================================
# STEP 14: Create Documentation
# ============================================================================
echo -e "${GREEN}Step 13:${NC} Creating documentation..."

mkdir -p docs

cat > docs/installation.md << 'EOF'
# Installation Guide

## Prerequisites

- Python 3.10+
- Ollama running on 3 nodes (or localhost)
- Optional: Go, Python, Dart compilers for validation

## Setup

```bash
# Clone repository
git clone <repo-url>
cd universal-project-generator

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Install in development mode
pip install -e .
```

## Configuration

Edit `config/cluster_config.yaml` to point to your Ollama nodes:

```yaml
architect:
  base_url: http://192.168.1.100:11434

coder:
  base_url: http://192.168.1.101:11434

reviewer:
  base_url: http://192.168.1.102:11434
```

## Verify Installation

```bash
project-gen --help
```
EOF

cat > docs/quick_start.md << 'EOF'
# Quick Start

## Generate Example Configs

```bash
project-gen examples
```

This creates:
- `config/cluster_config.yaml`
- `config/examples/go_microservice.yaml`
- `config/examples/python_api.yaml`
- `config/examples/flutter_app.yaml`

## Generate Your First Project

```bash
project-gen generate \
  --project config/examples/go_microservice.yaml \
  --cluster config/cluster_config.yaml
```

Output will be in `generated/auth-service/`

## Interactive Mode

```bash
project-gen init
```

Follow the prompts to create a custom project.
EOF

echo -e "  ${GREEN}✓${NC} Documentation created"

# ============================================================================
# STEP 15: Create TODO File
# ============================================================================
cat > TODO.md << 'EOF'
# TODO: Implementation Checklist

## Core (Complete these first)
- [x] Project structure
- [x] Configuration files
- [ ] src/core/schemas.py - Copy from monolithic file
- [ ] src/core/config.py - Copy from monolithic file
- [ ] src/core/state.py - Copy from monolithic file

## Clients
- [ ] src/clients/ollama_client.py - Copy OllamaClient class

## Validators
- [ ] src/validators/syntax_validator.py - Copy FileValidator
- [ ] src/validators/dependency_validator.py - Copy circular dependency detection
- [ ] src/validators/config_validator.py - Create ConfigValidator

## Formatters
- [ ] src/formatters/code_formatter.py - Copy CodeFormatter

## Generators
- [ ] src/generators/dependency_gen.py - Copy DependencyGenerator
- [ ] src/generators/deployment_gen.py - Copy DeploymentGenerator
- [ ] src/generators/doc_gen.py - Copy DocTestGenerator
- [ ] src/generators/test_gen.py - Create test generator
- [ ] src/generators/config_gen.py - Create config generator

## Agents
- [ ] src/agents/base.py - Create BaseAgent
- [ ] src/agents/architect.py - Copy ArchitectAgent
- [ ] src/agents/coder.py - Copy CoderAgent
- [ ] src/agents/reviewer.py - Copy ReviewerAgent
- [ ] src/agents/writer.py - Copy FileWriterAgent

## Workflow
- [ ] src/workflow/checkpoints.py - Copy CheckpointManager
- [ ] src/workflow/builder.py - Copy WorkflowBuilder

## CLI
- [ ] src/cli/commands.py - Create all commands
- [ ] src/cli/main.py - Create CLI entry point
- [ ] src/cli/interactive.py - Create interactive wizard

## Testing
- [ ] Write unit tests for all modules
- [ ] Write integration tests
- [ ] Test with all example configs

## Documentation
- [ ] Complete API reference
- [ ] Add architecture diagrams
- [ ] Create video tutorials
- [ ] Add more examples
EOF

# ============================================================================
# COMPLETION
# ============================================================================
echo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ Setup Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "${YELLOW}📂 Project Structure:${NC}"
echo "   ${PROJECT_NAME}/"
echo "   ├── src/              # Source code (copy classes here)"
echo "   ├── tests/            # Unit and integration tests"
echo "   ├── config/           # Configuration files"
echo "   ├── docs/             # Documentation"
echo "   └── scripts/          # Helper scripts"
echo
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo
echo "1. Enter project directory:"
echo -e "   ${BLUE}cd ${PROJECT_NAME}${NC}"
echo
echo "2. Activate virtual environment:"
echo -e "   ${BLUE}source venv/bin/activate${NC}"
echo
echo "3. Copy your code from the monolithic file to the appropriate modules"
echo -e "   See: ${BLUE}TODO.md${NC} for the complete checklist"
echo
echo "4. Install dependencies:"
echo -e "   ${BLUE}./scripts/install.sh${NC}"
echo
echo "5. Test your setup:"
echo -e "   ${BLUE}python -m src.cli.main examples${NC}"
echo -e "   ${BLUE}python -m src.cli.main generate --project config/examples/go_microservice.yaml${NC}"
echo
echo -e "${YELLOW}📚 Documentation:${NC}"
echo "   - README.md           # Project overview"
echo "   - TODO.md             # Implementation checklist"
echo "   - docs/installation.md # Setup guide"
echo "   - docs/quick_start.md  # Quick start guide"
echo
echo -e "${GREEN}Happy coding! 🚀${NC}"
echo
