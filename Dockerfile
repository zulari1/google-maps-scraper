FROM golang:1.25.3 AS builder
ENV GOTOOLCHAIN=auto
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o google-maps-scraper

FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libatspi2.0-0 \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    python3 \
    python3-venv \
    python3-pip \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/google-maps-scraper .
COPY apify_wrapper.py .
RUN python3 -m venv /venv && \
    /venv/bin/pip install --no-cache-dir apify
ENV PATH="/venv/bin:$PATH"
ENV ROD_CHROMIUM_PATH=/usr/bin/google-chrome-stable
ENTRYPOINT ["/venv/bin/python", "apify_wrapper.py"]
