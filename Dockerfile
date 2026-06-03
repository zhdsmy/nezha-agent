# syntax=docker/dockerfile:1

FROM alpine:3.23 AS downloader

ARG TARGETARCH
ARG VERSION=2.1.1

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN apk add --no-cache ca-certificates unzip wget \
    && case "${TARGETARCH}" in \
         amd64|arm64) AGENT_ARCH="${TARGETARCH}" ;; \
         *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
       esac \
    && AGENT_FILE="nezha-agent_linux_${AGENT_ARCH}.zip" \
    && wget -qO "/tmp/${AGENT_FILE}" "https://github.com/nezhahq/agent/releases/download/v${VERSION}/${AGENT_FILE}" \
    && wget -qO /tmp/checksums.txt "https://github.com/nezhahq/agent/releases/download/v${VERSION}/checksums.txt" \
    && AGENT_SHA256="$(awk -v file="${AGENT_FILE}" '$2 == file { print $1 }' /tmp/checksums.txt)" \
    && echo "${AGENT_SHA256}  /tmp/${AGENT_FILE}" | sha256sum -c - \
    && unzip -q "/tmp/${AGENT_FILE}" -d /tmp/nezha-agent \
    && install -m 0755 /tmp/nezha-agent/nezha-agent /usr/bin/nezha-agent

FROM alpine:3.23

ARG VERSION=2.1.1

LABEL org.opencontainers.image.title="nezha-agent" \
      org.opencontainers.image.description="Docker image for Nezha Agent" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.source="https://github.com/zhdsmy/nezha-agent" \
      org.opencontainers.image.licenses="Apache-2.0"

RUN apk add --no-cache ca-certificates docker-cli iproute2 iputils procps

COPY --from=downloader /usr/bin/nezha-agent /usr/bin/nezha-agent
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN mkdir -p /etc/nezha-agent /var/lib/nezha-agent \
    && chmod +x /usr/local/bin/entrypoint.sh \
    && nezha-agent --version

WORKDIR /var/lib/nezha-agent

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
