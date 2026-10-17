# Development image for the Flask API (TFQD-8).
# This is not the production image. Staging and production are TFQD-10.

FROM python:3.13-slim

# No .pyc files, and print logs at once instead of holding them in a buffer.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Copy only the requirements first. Docker reuses this layer (and skips the
# install) as long as the requirements files do not change.
COPY requirements.txt requirements-dev.txt ./
RUN pip install --no-cache-dir -r requirements-dev.txt

COPY . .

# Run as a normal user, not as root.
RUN useradd --create-home appuser && chown -R appuser /app
USER appuser

EXPOSE 5000

# docker-compose.yml starts the server with its own command (with auto-reload).
CMD ["flask", "--app", "wsgi", "run", "--host", "0.0.0.0", "--port", "5000"]
