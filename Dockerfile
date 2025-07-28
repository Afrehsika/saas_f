# Set the Python version as a build-time argument (default: 3.12-slim-bullseye)
ARG PYTHON_VERSION=3.12-slim-bullseye
FROM python:${PYTHON_VERSION}

# Set environment variables
ENV PATH=/opt/venv/bin:$PATH \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create and activate virtual environment
RUN python -m venv /opt/venv && \
    pip install --upgrade pip

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libjpeg-dev \
    libcairo2 \
    gcc \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create the working directory
WORKDIR /code

# Copy requirements and install them
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Copy the Django project source code
COPY ./src /code

# Set the Django project name
ARG PROJ_NAME="core"

# Create the startup script
RUN echo '#!/bin/bash' > paracord_runner.sh && \
    echo 'set -e' >> paracord_runner.sh && \
    echo 'RUN_PORT="${PORT:-8000}"' >> paracord_runner.sh && \
    echo 'echo "Running migrations..."' >> paracord_runner.sh && \
    echo 'python manage.py migrate --no-input' >> paracord_runner.sh && \
    echo '# Uncomment the next line if using collectstatic' >> paracord_runner.sh && \
    echo '# python manage.py collectstatic --no-input' >> paracord_runner.sh && \
    echo 'echo "Starting Gunicorn server..."' >> paracord_runner.sh && \
    echo "gunicorn ${PROJ_NAME}.wsgi:application --bind \"[::]:\$RUN_PORT\"" >> paracord_runner.sh && \
    chmod +x paracord_runner.sh

# Run the startup script on container start
CMD ["bash", "./paracord_runner.sh"]
