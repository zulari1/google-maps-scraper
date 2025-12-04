# Build the Go binary
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o google-maps-scraper

# Final minimal image
FROM alpine:3.20

# Install Python + Apify SDK + Chromium (needed for rod)
RUN apk add --no-cache \
    python3 \
    py3-pip \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont

# Install Apify SDK
RUN pip3 install --no-cache-dir apify

# Copy binary
WORKDIR /app
COPY --from=builder /app/google-maps-scraper .
COPY apify_wrapper.py .

# Tell rod where Chromium is
ENV ROD_CHROMIUM_PATH=/usr/bin/chromium-browser

# Apify entrypoint
ENTRYPOINT ["python3", "apify_wrapper.py"]
