# syntax=docker/dockerfile:1

# Rebuild the same release with Go's fixed x509 verifier.
# hadolint ignore=DL3029
FROM --platform=$BUILDPLATFORM golang:1.26.10-alpine3.24 AS builder
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
ARG TARGETARCH
ARG VERSION=2.3.3
ARG SOURCE_REVISION=fe293de791bf9062c4854d059597e414fbea8cb0
ARG SOURCE_SHA256=e40dcb8f13f6ff1171994d3f7b9bfdff9bd5286e53412d7fc9f04b9ec774b812
RUN apk add --no-cache --upgrade ca-certificates ca-certificates-bundle
RUN wget -q -O /tmp/source.tar.gz "https://codeload.github.com/nezhahq/agent/tar.gz/${SOURCE_REVISION}" \
    && echo "${SOURCE_SHA256}  /tmp/source.tar.gz" | sha256sum -c -
RUN mkdir /src && tar -xzf /tmp/source.tar.gz --strip-components=1 -C /src
WORKDIR /src
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go get github.com/klauspost/compress@v1.18.7 golang.org/x/net@v0.61.0 google.golang.org/grpc@v1.83.2 \
    && go mod tidy \
    && CGO_ENABLED=0 GOTOOLCHAIN=local GOOS=linux GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w -X github.com/nezhahq/agent/pkg/monitor.Version=${VERSION} -X main.arch=${TARGETARCH}" -o /usr/bin/nezha-agent ./cmd/agent

FROM domizhang/nezha-agent@sha256:997de9766a30e3db0d5d6dff6802020b0eb250375db792d55f302d636977dfc8 AS runtime
COPY --from=builder /usr/bin/nezha-agent /usr/bin/nezha-agent
LABEL org.opencontainers.image.version="2.3.3" \
      org.opencontainers.image.revision="fe293de791bf9062c4854d059597e414fbea8cb0"
