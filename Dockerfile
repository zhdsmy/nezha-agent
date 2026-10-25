# syntax=docker/dockerfile:1

# Rebuild the same release with Go's fixed x509 verifier.
# hadolint ignore=DL3029
FROM --platform=$BUILDPLATFORM golang:1.26.10-alpine3.24 AS builder
ARG TARGETARCH
ARG VERSION=2.4.0
ARG SOURCE_REVISION=2c33791c40c81154da4eb972f1257faa8c4180e8
ARG SOURCE_SHA256=2c5bc3ca28cf34a429814114ae12d0e6bf2b2ea5da792239128247edebc2f55b
RUN apk add --no-cache --upgrade ca-certificates ca-certificates-bundle
RUN wget -q -O /tmp/source.tar.gz "https://codeload.github.com/nezhahq/agent/tar.gz/${SOURCE_REVISION}" \
    && echo "${SOURCE_SHA256}  /tmp/source.tar.gz" | sha256sum -c -
RUN mkdir /src && tar -xzf /tmp/source.tar.gz --strip-components=1 -C /src
WORKDIR /src
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOTOOLCHAIN=local GOOS=linux GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w -X github.com/nezhahq/agent/pkg/monitor.Version=${VERSION} -X main.arch=${TARGETARCH}" -o /usr/bin/nezha-agent ./cmd/agent

FROM alpine:3.24 AS runtime

ARG VERSION=2.4.0

LABEL org.opencontainers.image.title="nezha-agent" \
      org.opencontainers.image.description="Docker image for Nezha Agent" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.source="https://github.com/zhdsmy/nezha-agent" \
      org.opencontainers.image.licenses="Apache-2.0"

RUN apk add --no-cache --upgrade ca-certificates ca-certificates-bundle docker-cli iproute2 iputils procps libcrypto3 libssl3

COPY --from=builder /usr/bin/nezha-agent /usr/bin/nezha-agent
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN mkdir -p /etc/nezha-agent /var/lib/nezha-agent \
    && chmod +x /usr/local/bin/entrypoint.sh \
    && nezha-agent --version

WORKDIR /var/lib/nezha-agent

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
