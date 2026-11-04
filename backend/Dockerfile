# The image of the Flask API. The same image runs on a laptop and on Render:
# docker-compose.yml starts the development server with its own command, and
# Render (or any plain `docker run`) uses the CMD at the end.

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

# Update the database first (every new migration in migrations/versions);
# with DEMO_DATA=true, make the demo data when it is not there yet; then start
# the production server (gunicorn) on the port Render gives in $PORT (5000
# when nothing sets it). docker-compose.yml replaces this command.
CMD ["sh", "-c", "flask --app wsgi db upgrade && if [ \"$DEMO_DATA\" = true ]; then flask --app wsgi demo-data --if-missing; fi && exec gunicorn --bind 0.0.0.0:${PORT:-5000} --workers 2 --timeout 120 --access-logfile - wsgi:app"]
