#!/bin/sh

# Wait for Redis to be ready
while ! nc -z redis 6379; do
  echo "Waiting for Redis..."
  sleep 1
done

# Start the application
exec uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4