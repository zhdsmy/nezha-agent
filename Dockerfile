# syntax=docker/dockerfile:1

# Rebuild the same release with Go's fixed x509 verifier.
# hadolint ignore=DL3029
FROM --platform=$BUILDPLATFORM golang:1.26.11-alpine3.24 AS builder
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
ARG TARGETARCH
ARG VERSION=2.5.0
ARG SOURCE_REVISION=4b0ff06ca4a518aebebb4044168b96fcbfcdc668
ARG SOURCE_SHA256=690e879a66168e75de32b61a02496f6cf5630c33536114af7395af20907f11ba
RUN apk add --no-cache --upgrade ca-certificates ca-certificates-bundle
RUN wget -q -O /tmp/source.tar.gz "https://codeload.github.com/nezhahq/agent/tar.gz/${SOURCE_REVISION}" \
    && echo "${SOURCE_SHA256}  /tmp/source.tar.gz" | sha256sum -c -
RUN mkdir /src && tar -xzf /tmp/source.tar.gz --strip-components=1 -C /src
WORKDIR /src
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go get golang.org/x/net@v0.62.0 && go mod tidy \
    && CGO_ENABLED=0 GOTOOLCHAIN=local GOOS=linux GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w -X github.com/nezhahq/agent/pkg/monitor.Version=${VERSION} -X main.arch=${TARGETARCH}" -o /usr/bin/nezha-agent ./cmd/agent

FROM alpine:3.24 AS runtime

ARG VERSION=2.5.0

LABEL org.opencontainers.image.title="nezha-agent" \
      org.opencontainers.image.description="Docker image for Nezha Agent" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.source="https://github.com/zhdsmy/nezha-agent" \
      org.opencontainers.image.licenses="Apache-2.0"

RUN apk upgrade --no-cache \
    && apk add --no-cache --upgrade ca-certificates ca-certificates-bundle docker-cli iproute2 iputils procps libcrypto3 libssl3

COPY --from=builder /usr/bin/nezha-agent /usr/bin/nezha-agent
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN mkdir -p /etc/nezha-agent /var/lib/nezha-agent \
    && chmod +x /usr/local/bin/entrypoint.sh \
    && nezha-agent --version

WORKDIR /var/lib/nezha-agent

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
