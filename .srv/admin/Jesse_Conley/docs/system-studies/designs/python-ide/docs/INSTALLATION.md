### **🚀 Installation Commands**

**Basic Installation:**
```bash
# Install the package in development mode
pip install -e .

# Or install specific optional dependencies
pip install -e .[dev]           # Development tools
pip install -e .[gpu]           # GPU support
pip install -e .[production]    # Production deployment
pip install -e .[all]           # Everything
```

**From requirements.txt:**
```bash
pip install -r requirements.txt              # Basic
pip install -r requirements-dev.txt          # Development
pip install -r requirements-gpu.txt          # GPU support
```

**Poetry (alternative):**
```bash
# Install poetry first
curl -sSL https://install.python-poetry.org | python3 -

# Install project
poetry install                    # Basic
poetry install --extras "dev"    # With dev dependencies
poetry install --extras "gpu"    # With GPU support
poetry install --extras "all"    # Everything
```

---

### **🔧 Development Setup**

```bash
# Clone and setup
git clone <your-repo>
cd ai-assistant

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows

# Install in development mode
pip install -e .[dev]

# Setup pre-commit hooks
pre-commit install

# Run tests
pytest

# Run with development server
python -m uvicorn backend.app.main:app --reload
```