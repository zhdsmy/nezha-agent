# nezha-agent

Docker image for [Nezha Agent](https://github.com/nezhahq/agent), the agent component of Nezha Monitoring.

[![Docker Pulls](https://img.shields.io/docker/pulls/domizhang/nezha-agent.svg)](https://hub.docker.com/r/domizhang/nezha-agent)
[![Docker Image Size](https://img.shields.io/docker/image-size/domizhang/nezha-agent/latest)](https://hub.docker.com/r/domizhang/nezha-agent)

## Included version

- Nezha Agent: `2.3.0`
- Base image: `alpine:3.23`
- Includes Docker CLI for dashboard-triggered container operations when the Docker socket is mounted.
- Release artifacts are verified with upstream `checksums.txt` during build.

## Supported platforms

- `linux/amd64`
- `linux/arm64`

## Tags

- `latest`: latest build from the default branch
- `2.3.0`: current Nezha Agent version build
- `2.1`: major/minor tag for versioned releases

## Configuration

This image is config-file first. Mount `/etc/nezha-agent/config.yml` so upstream configuration changes do not require image or entrypoint changes.

Nezha Agent also reads upstream native `NZ_` environment variables from the process environment. For example, `NZ_SERVER` maps to `server` and `NZ_CLIENT_SECRET` maps to `client_secret`. These variables are handled by Nezha Agent itself, not by this image.

The entrypoint only adds two image-level variables:

- `NEZHA_AGENT_CONFIG`: config file path, defaults to `/etc/nezha-agent/config.yml`
- `NEZHA_AGENT_ARGS`: optional extra arguments appended to `nezha-agent -c "$NEZHA_AGENT_CONFIG"`

Minimal `config.yml`:

```yaml
server: example.com:5555
client_secret: your_client_secret
tls: true
disable_auto_update: true
disable_force_update: true
disable_command_execute: true
```

## Quick start

Run with a mounted config file:

```bash
docker run -d \
  --name nezha-agent \
  --restart unless-stopped \
  -v "$PWD/config.yml:/etc/nezha-agent/config.yml:ro" \
  domizhang/nezha-agent:latest
```

Run with upstream native environment variables:

```bash
docker run -d \
  --name nezha-agent \
  --restart unless-stopped \
  -e NZ_SERVER="example.com:5555" \
  -e NZ_CLIENT_SECRET="your_client_secret" \
  -e NZ_TLS="true" \
  -e NZ_DISABLE_AUTO_UPDATE="true" \
  domizhang/nezha-agent:latest
```

Show help:

```bash
docker run --rm domizhang/nezha-agent:latest nezha-agent --help
```

## Docker Compose

```yaml
services:
  nezha-agent:
    image: domizhang/nezha-agent:latest
    container_name: nezha-agent
    restart: unless-stopped
    volumes:
      - ./config.yml:/etc/nezha-agent/config.yml:ro
```

## Build locally

```bash
docker build \
  --build-arg VERSION=2.3.0 \
  -t domizhang/nezha-agent:local .
```

## Update policy

The Nezha Agent version is pinned in `VERSION`, `Dockerfile`, and `README.md`. To update:

1. Check the upstream [Nezha Agent releases](https://github.com/nezhahq/agent/releases).
2. Update the `VERSION` file and `ARG VERSION` defaults.
3. Build and test the image.
4. Tag the repository as `vX.Y.Z` to publish versioned tags.

## License

This repository only builds a Docker image. Nezha Agent is distributed under the Apache-2.0 license.
