FROM python:3.10-bookworm

# Install GNU Octave and its dependencies
RUN apt-get update && apt-get install -y \
    octave \
    liboctave-dev \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory to the project root
WORKDIR /app

# Create a non-root user (HF Spaces requires this for security)
RUN useradd -m -u 1000 user

# Copy the entire project so we get both folders
COPY --chown=user:user . /app

# Install Python packages
# Upgrade pip to avoid compilation failures on older wheels
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /app/backend_hf/requirements.txt

# Switch to the non-root user
USER user

# Set environment variable to force FastAPI to log instantly
ENV PYTHONUNBUFFERED=1

# Run Uvicorn on port 7860 (Hugging Face Spaces default port)
CMD ["python", "-m", "uvicorn", "backend_hf.main:app", "--host", "0.0.0.0", "--port", "7860", "--timeout-keep-alive", "120"]
