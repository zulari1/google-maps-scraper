# Build the Go binary with recommended version
FROM golang:1.25.3-alpine AS builder
ENV GOTOOLCHAIN=auto  # Enables automatic toolchain upgrades for tool blocks
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o google-maps-scraper

# Final minimal image with Apify support
FROM alpine:3.20

# Install Python, Apify SDK, and Chromium (for rod browser)
RUN apk add --no-cache \
    python3 \
    py3-pip \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont

# Install Apify SDK (no system packages conflict)
RUN pip3 install --no-cache-dir apify

# Copy binary and wrapper
WORKDIR /app
COPY --from=builder /app/google-maps-scraper .
COPY apify_wrapper.py .

# Rod browser config
ENV ROD_CHROMIUM_PATH=/usr/bin/chromium-browser

# Apify entrypoint
ENTRYPOINT ["python3", "apify_wrapper.py"]
