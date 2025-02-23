FROM python:3.9-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy processing script
COPY process.py .

# Environment variables will be provided by AWS Batch
ENV BUCKET_NAME=""
ENV INPUT_KEY=""
ENV OUTPUT_KEY=""

CMD ["python", "process.py"] 