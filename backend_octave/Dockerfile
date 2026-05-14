# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Install GNU Octave and its dependencies
RUN apt-get update && apt-get install -y \
    octave \
    liboctave-dev \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory to the project root
# This ensures it can find both backend_octave and multi_layer_ganquila
WORKDIR /app

# Copy the entire project so we get both folders
COPY . /app

# Install Python packages
WORKDIR /app/backend_octave
RUN pip install --no-cache-dir -r requirements.txt

# Run the FastAPI server
CMD ["python", "main.py"]
