FROM python:3.13-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# Use Gunicorn with uvicorn workers for best async performance
CMD ["gunicorn", "app.asgi:application", "-k", "uvicorn.workers.UvicornWorker", "-w", "4", "-b", "0.0.0.0:8000", "--log-level", "warning"]
