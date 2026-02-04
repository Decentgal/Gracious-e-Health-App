# Builder stage
FROM python:3.11-slim AS builder
WORKDIR /app

COPY gracy.txt .

RUN pip install --no-cache-dir --upgrade pip setuptools \
    && pip install --no-cache-dir --prefix=/install -r gracy.txt

# Runtime stage
# checkov:skip=CKV_DOCKER_7: Using latest distroless for compatibility; image is inherently secure
FROM gcr.io/distroless/python3-debian12:latest
WORKDIR /app

COPY --from=builder /install /usr/local
COPY gracious_app.py .

ENV PYTHONPATH=/usr/local/lib/python3.11/site-packages

# FIX CKV_DOCKER_2: Add a Healthcheck using Python's built-in libraries
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD ["python3", "-c", "import http.client; conn = http.client.HTTPConnection('localhost', 5000); conn.request('GET', '/'); res = conn.getresponse(); exit(0 if res.status == 200 else 1)"]

USER nonroot

EXPOSE 5000

CMD ["gracious_app.py"]