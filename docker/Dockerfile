# syntax=docker/dockerfile:1

FROM python:3.11-slim AS builder
ENV PYTHONUNBUFFERED=1
WORKDIR /app

# install uv without pip
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/* \
    && curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

COPY . /app
RUN uv pip install --system .

FROM python:3.11-slim AS runtime
ENV PYTHONUNBUFFERED=1
WORKDIR /app

COPY --from=builder /usr/local /usr/local
COPY --from=builder /app /app

CMD ["python", "-m", "bot.app"]
