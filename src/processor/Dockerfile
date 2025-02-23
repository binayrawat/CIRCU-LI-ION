FROM python:3.9-slim

# Create non-root user
RUN useradd -m -r -u 1001 processor

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies as root
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY process.py .

# Set ownership
RUN chown -R processor:processor /app

# Switch to non-root user
USER processor

# Command to run the application
CMD ["python", "process.py"]
