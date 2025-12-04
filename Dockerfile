FROM golang:1.25.3-alpine AS builder
ENV GOTOOLCHAIN=auto
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o google-maps-scraper

FROM alpine:3.20
RUN apk add --no-cache \
    python3 \
    py3-pip \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont
RUN pip3 install --no-cache-dir apify
WORKDIR /app
COPY --from=builder /app/google-maps-scraper .
COPY apify_wrapper.py .
ENV ROD_CHROMIUM_PATH=/usr/bin/chromium-browser
ENTRYPOINT ["python3", "apify_wrapper.py"]
