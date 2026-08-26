# Estagio 1: Build de dependencias
FROM python:3.12-alpine AS builder

WORKDIR /build

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apk add --no-cache gcc musl-dev libffi-dev

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Estagio 2: Runtime Distroless com patches diarios
FROM cgr.dev/chainguard/python:latest

WORKDIR /app

# Copia dependencias isoladas do build stage
COPY --from=builder /install /home/nonroot/.local
COPY main.py .

ENV PATH=/home/nonroot/.local/bin:$PATH \
    PYTHONPATH=/home/nonroot/.local/lib/python3.12/site-packages \
    APP_ENV=production \
    PORT=8000

USER nonroot

EXPOSE 8000

ENTRYPOINT ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]