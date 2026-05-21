FROM python:3.10-bookworm

# Install GNU Octave and its dependencies
RUN apt-get update && apt-get install -y \
    octave \
    liboctave-dev \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory to the project root
WORKDIR /app

# Copy the entire project so we get both folders
COPY . /app

# Install Python packages
# FIX 1: Upgrade pip to avoid compilation failures on older wheels
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /app/backend_octave/requirements.txt

# FIX 2: Set environment variable to force FastAPI to log instantly
ENV PYTHONUNBUFFERED=1

# FIX 3: Do not use python main.py in production. Use Uvicorn with explicit host and port bind.
# Note: Using python -m uvicorn to ensure it runs from the correct directory context
CMD ["python", "-m", "uvicorn", "backend_octave.main:app", "--host", "0.0.0.0", "--port", "10000", "--timeout-keep-alive", "120"]
