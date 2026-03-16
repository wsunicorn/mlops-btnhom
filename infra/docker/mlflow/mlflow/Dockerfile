FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy and install python packages with retry and timeout
COPY requirements.txt /tmp
RUN pip install --no-cache-dir --default-timeout=1000 --retries 5 -r /tmp/requirements.txt