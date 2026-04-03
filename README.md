# Seanime Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/ghcr.io/awu05/seanime-docker.svg)](https://hub.docker.com/r/ghcr.io/awu05/seanime-docker)
[![Build, Test & Publish](https://github.com/umag/seanime-docker/actions/workflows/build-test-publish.yml/badge.svg)](https://github.com/umag/seanime-docker/actions/workflows/build-test-publish.yml)
[![CI](https://github.com/umag/seanime-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/umag/seanime-docker/actions/workflows/ci.yml)

A simple, multi-arch Docker image for [Seanime](https://seanime.rahim.app/).

> **Note**: Hardware acceleration variants (hwaccel and CUDA) are built and
> published automatically, but cannot be fully tested during the build process
> due to the lack of specific hardware (Intel QSV/VAAPI or NVIDIA GPUs) on
> GitHub Actions runners. While basic image structure and functionality are
> verified, hardware-specific features should be tested in your own environment.

## Image Variants

We provide three image variants to suit different needs:

| Variant      | Tag               | User                | Description                                             |
| ------------ | ----------------- | ------------------- | ------------------------------------------------------- |
| **Default**  | `latest`          | `root`              | Standard setup (Alpine + FFmpeg). Backward compatible.  |
| **Rootless** | `latest-rootless` | `seanime` (1000)    | Security-focused, runs as non-root user.                |
| **HwAccel**  | `latest-hwaccel`  | `seanime` (1000)    | Rootless + Jellyfin-FFmpeg + Intel Drivers (QSV/VAAPI). |
| **CUDA**     | `latest-cuda`     | `seanime` (1001!!!) | Rootless + FFmpeg (NVENC) + NVIDIA CUDA Base.           |

## Usage

### Quick Start (Default)

The default image runs as root, similar to previous versions.

```yaml
services:
  seanime:
    image: ghcr.io/awu05/seanime-docker:latest
    container_name: seanime
    volumes:
      - /mnt/user/anime:/anime
      - /mnt/user/downloads:/downloads
      - ./config:/root/.config
    environment:
      - QBIT_WEBUI_PORT=8081
      - QBIT_USERNAME=admin
      - QBIT_PASSWORD=adminadmin
    ports:
      - 3211:43211
      - 8081:8081
    restart: unless-stopped
```

### Examples

Check the [examples](./examples) directory for complete configurations:

- **[01-Default](./examples/01-default)**: Standard root-based setup.
- **[02-Rootless](./examples/02-rootless)**: Secure non-root setup.
- **[03-HwAccel](./examples/03-hwaccel)**: Hardware acceleration (Intel) setup.
- **[04-CUDA](./examples/04-hwaccel-cuda)**: Hardware acceleration (NVIDIA CUDA)
  setup.

## Configuration

### Environment Variables

| Variable         | Default      | Description                          |
| ---------------- | ------------ | ------------------------------------ |
| `QBIT_WEBUI_PORT`| `8081`       | qBittorrent WebUI port.              |
| `QBIT_USERNAME`  | `admin`      | qBittorrent WebUI username.          |
| `QBIT_PASSWORD`  | `adminadmin` | qBittorrent WebUI password.          |

### Ports

| Port | Description |
| --- | --- |
| `3211` | External port mapping to container's `43211`. |
| `8081` | qBittorrent WebUI (configurable via `QBIT_WEBUI_PORT`). |

### Volumes

#### Default Variant

- `/root/.config` - Configuration files (Seanime + qBittorrent).

#### Rootless & HwAccel Variants

- `/home/seanime/.config` - Configuration files (Seanime + qBittorrent).
- **Note**: Ensure the host directory for config is writable by UID 1000.

#### Common

- `/anime` - Media library (mount your anime directory here).
- `/downloads` - Downloads directory.

## Hardware Acceleration

### Intel QSV/VAAPI

To use hardware acceleration (Intel QSV/VAAPI):

1. Use the `latest-hwaccel` tag.
2. Pass the device `/dev/dri` to the container.
3. Only supported on `amd64` architecture (falls back to software on others).

```yaml
services:
  seanime:
    image: ghcr.io/awu05/seanime-docker:latest-hwaccel
    devices:
      - /dev/dri:/dev/dri
    # ... other config
```

### NVIDIA CUDA (NVENC/NVDEC)

To use NVIDIA hardware acceleration:

1. Use the `latest-cuda` tag.
2. Ensure NVIDIA drivers and Container Toolkit are installed on the host.
3. Configure the runtime to `nvidia`.

```yaml
services:
  seanime:
    image: ghcr.io/awu05/seanime-docker:latest-cuda
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
    # ... other config
```

## Development & Testing

This project uses [Nix](https://nixos.org/) and [direnv](https://direnv.net/) to
manage development dependencies.

### Setup

1. Install **Nix** and **direnv**.
2. Run `direnv allow` in the project root.
3. This will install:
   - `container-structure-test`
   - `goss` / `dgoss`
   - `bats`
   - `hadolint`

### Running Tests

We use **BATS** to orchestrate all tests.

#### 1. Image Verification (Structure & Goss)

This suite pulls all image variants and runs both Container Structure Tests and
Goss tests against them.

```bash
bats tests/images.bats
```

#### 2. Docker Compose Integration

This suite verifies the example Compose configurations.

```bash
bats tests/compose.bats
```
