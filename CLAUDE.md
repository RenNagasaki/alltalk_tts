# CLAUDE.md

## Overview

Fork of [erew123/alltalk_tts](https://github.com/erew123/alltalk_tts) (alltalkbeta branch) with custom GitLab CI for building Docker images. Deployed as TTS service on the k3s homelab cluster.

## Source

- **Upstream**: `https://github.com/erew123/alltalk_tts` branch `alltalkbeta`
- **GitLab**: `https://gitlab.echotools.cloud/echotools/alltalk_tts`
- **Rule**: Do NOT modify upstream files. Only add new files (`.gitlab-ci.yml`, `CLAUDE.md`).

## Docker Build

### Architecture
Two-stage build:
1. **Base image** (`docker/base/Dockerfile`): miniconda + CUDA + PyTorch + conda env. Built and published by upstream to Docker Hub as `erew123/alltalk_tts_environment:latest`. We do NOT build this ourselves — too heavy for DinD.
2. **Main image** (`Dockerfile`): Installs pip deps, deepspeed, downloads TTS models, runs firstrun.py. Built by our GitLab CI. Pushed to `registry.echotools.cloud/echotools/alltalk_tts:latest-xtts`.

### GitLab CI Pipeline
- Uses Docker-in-Docker (DinD) with explicit `--storage-driver=overlay2` and `--default-ulimit nofile=65536:65536`
- No TLS between build and DinD (port 2375) — same pod, no security risk
- DinD service defined in `.gitlab-ci.yml` with `command` override (runner config can't pass args to service containers)
- Base image pulled from Docker Hub (`erew123/alltalk_tts_environment:latest`)

### Known Issues / History
- **VFS storage driver on virtiofs**: The GitLab runner stores Docker data on a virtiofs hostPath (`/mnt/data_d`). Docker defaults to the VFS driver on virtiofs, which opens one file descriptor per file per layer. Large images (conda env has ~300k files) hit the `too many open files` system limit. Fix: force `overlay2` via `--storage-driver=overlay2` on the DinD service command.
- **DinD crashes with TLS**: Cert-sharing between build and DinD containers via emptyDir volumes was unreliable. Fix: disable TLS (`DOCKER_TLS_CERTDIR=""`, port 2375).
- **DinD crashes with emptyDir for /var/lib/docker**: Attempted switching from virtiofs hostPath to emptyDir for overlay2 support, but DinD crashed. Reverted — the `command` override on the service container is the correct way to force overlay2.
- **Kaniko doesn't work**: The Dockerfile relies heavily on `SHELL ["/bin/bash", "-l", "-c"]` and `conda activate` between layers. Kaniko doesn't handle conda environment activation across layers properly (`requests` module not found despite being installed).
- **Token expiry on long builds**: Docker registry auth token can expire during multi-hour builds. Fix: re-login before push.

## Deployment

Deployed in `echotools` namespace on the k3s cluster as 3 TTS instances (ttsren, ttsmona, ttsdom). See `F:\Git-Repositories\Proxmox-Cluster\k8s\echotools\alltalk-deployments.yaml`.

## Variables

Sourced from `docker/variables.sh`:
- `CUDA_VERSION`: 12.8.1
- `PYTHON_VERSION`: 3.11.11
- `DEEPSPEED_VERSION`: 0.17.2
