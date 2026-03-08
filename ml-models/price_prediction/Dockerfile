# syntax=docker/dockerfile:1.7

FROM python:3.11-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Create an isolated venv to keep runtime image minimal
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Use the requirements from the local_price subfolder
COPY local_price/requirements.txt ./requirements.txt

# Install dependencies with pip cache mount for faster rebuilds
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    pip install -r requirements.txt

FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Install minimal system libs required by common scientific packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd --system appuser && useradd --system --gid appuser --create-home appuser

WORKDIR /app

# Copy venv from builder and project files
COPY --from=builder /opt/venv /opt/venv
COPY --chown=appuser:appuser . /app

USER appuser

EXPOSE 8000

# Serve the FastAPI app defined in local_price/main.py
CMD ["uvicorn", "local_price.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
