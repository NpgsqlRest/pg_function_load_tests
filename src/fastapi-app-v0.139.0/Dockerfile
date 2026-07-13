FROM python:3.14-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8001

# Use uvloop for maximum async performance.
# Workers = CPU cores so the single-threaded event loop can use the whole machine,
# matching natively multi-threaded runtimes (Go, Rust, .NET, JVM).
CMD uvicorn app:app --host 0.0.0.0 --port 8001 --workers ${WORKERS:-$(nproc)} --loop uvloop --http httptools --no-access-log --log-level warning
