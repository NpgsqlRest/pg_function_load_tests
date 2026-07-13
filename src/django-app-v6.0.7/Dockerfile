FROM python:3.14-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# Use Gunicorn with uvicorn workers for best async performance.
# Workers = CPU cores so the event loop can use the whole machine,
# matching natively multi-threaded runtimes (Go, Rust, .NET, JVM).
CMD gunicorn app.asgi:application -k uvicorn.workers.UvicornWorker -w ${WORKERS:-$(nproc)} -b 0.0.0.0:8000 --log-level warning
