# Multi-stage build for AI Assistant
FROM python:3.11-slim as builder

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    pkg-config \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy requirements first for better caching
COPY pyproject.toml requirements.txt ./

# Install Python dependencies
RUN pip install --upgrade pip setuptools wheel
RUN pip install -r requirements.txt

# Production stage
FROM python:3.11-slim as production

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV APP_ENV=production

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user
RUN groupadd -r aiassistant && useradd -r -g aiassistant aiassistant

# Create app directory and set permissions
WORKDIR /app
RUN chown -R aiassistant:aiassistant /app

# Copy Python packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Create necessary directories
RUN mkdir -p \
    /app/data/conversations \
    /app/data/embeddings \
    /app/data/knowledge \
    /app/data/logs \
    /app/data/models \
    /app/data/backups \
    /app/workspace \
    /app/templates \
    /app/static \
    && chown -R aiassistant:aiassistant /app/data /app/workspace

# Copy application code
COPY --chown=aiassistant:aiassistant backend/ ./backend/
COPY --chown=aiassistant:aiassistant templates/ ./templates/
COPY --chown=aiassistant:aiassistant static/ ./static/
COPY --chown=aiassistant:aiassistant migrations/ ./migrations/
COPY --chown=aiassistant:aiassistant .env.example ./.env

# Switch to non-root user
USER aiassistant

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/ping || exit 1

# Default command
CMD ["python", "-m", "uvicorn", "backend.app.main:app", "--host", "0.0.0.0", "--port", "8000"]