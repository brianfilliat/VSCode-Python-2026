FROM python:3.12-slim

WORKDIR /app

# Copy repository contents into the image.
COPY . .

# Default command keeps the image runnable even without a specific app entrypoint.
CMD ["python", "--version"]
