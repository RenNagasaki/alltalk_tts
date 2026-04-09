#!/usr/bin/env bash
# ============================================================================
# Build DeepSpeed wheel for Linux (via Docker)
# Targets: Blackwell (RTX 5090/5080/5070) + older architectures
# Requires: Docker with NVIDIA GPU support
# ============================================================================
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

DEEPSPEED_VERSION="${DEEPSPEED_VERSION:-0.17.2}"
CUDA_VERSION="${CUDA_VERSION:-12.8.1}"
PYTHON_VERSION="${PYTHON_VERSION:-3.11.11}"
BUILD_DIR="$SCRIPT_DIR/deepspeed_build"

# CUDA compute capabilities:
#   8.0  = Ampere data center (A100)
#   8.6  = Ampere consumer (RTX 3060/3070/3080/3090)
#   8.9  = Ada Lovelace (RTX 4060/4070/4080/4090)
#   12.0 = Blackwell consumer (RTX 5070/5080/5090)
TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST:-8.0;8.6;8.9;12.0}"

echo ""
echo "============================================================"
echo " DeepSpeed $DEEPSPEED_VERSION Wheel Builder for Linux"
echo " CUDA: $CUDA_VERSION  Python: $PYTHON_VERSION"
echo " CUDA architectures: $TORCH_CUDA_ARCH_LIST"
echo "============================================================"
echo ""

mkdir -p "$BUILD_DIR/wheels"

# Check if wheel already exists
if ls "$BUILD_DIR/wheels"/deepspeed-${DEEPSPEED_VERSION}*-cp311-cp311-linux*.whl 1>/dev/null 2>&1; then
    echo "DeepSpeed wheel already built — skipping."
    echo "Delete $BUILD_DIR/wheels/ to force a rebuild."
    ls "$BUILD_DIR/wheels"/*.whl
    exit 0
fi

# Build using Docker
DOCKER_IMAGE="deepspeed-builder:ds${DEEPSPEED_VERSION}-cu${CUDA_VERSION}"

echo "Building Docker image..."
docker build \
    --build-arg CUDA_VERSION="$CUDA_VERSION" \
    --build-arg PYTHON_VERSION="$PYTHON_VERSION" \
    --build-arg DEEPSPEED_VERSION="$DEEPSPEED_VERSION" \
    --build-arg TORCH_CUDA_ARCH_LIST="$TORCH_CUDA_ARCH_LIST" \
    -t "$DOCKER_IMAGE" \
    -f - "$SCRIPT_DIR" <<'DOCKERFILE'
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu22.04

ARG CUDA_VERSION=12.8.1
ARG PYTHON_VERSION=3.11.11
ARG DEEPSPEED_VERSION=0.17.2
ARG TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;12.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV TORCH_CUDA_ARCH_LIST=$TORCH_CUDA_ARCH_LIST

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl build-essential libaio-dev software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y python3.11 python3.11-dev python3.11-venv && \
    rm -rf /var/lib/apt/lists/*

RUN python3.11 -m ensurepip && python3.11 -m pip install --upgrade pip setuptools wheel

# Install PyTorch matching CUDA version
RUN CUDA_SHORT=$(echo $CUDA_VERSION | cut -d. -f1,2 | tr -d '.') && \
    python3.11 -m pip install torch==2.7.1 --index-url https://download.pytorch.org/whl/cu${CUDA_SHORT}

# Clone and build DeepSpeed
RUN git clone --depth 1 --branch "v${DEEPSPEED_VERSION}" https://github.com/microsoft/DeepSpeed.git /opt/DeepSpeed

WORKDIR /opt/DeepSpeed
ENV DS_BUILD_OPS=1
ENV DS_BUILD_AIO=1
ENV DS_BUILD_SPARSE_ATTN=0

RUN python3.11 setup.py build_ext -j$(nproc) bdist_wheel && \
    mkdir -p /output && cp dist/*.whl /output/

CMD ["bash", "-c", "cp /output/*.whl /build/"]
DOCKERFILE

echo "Running build container..."
docker run --rm --gpus all \
    -v "$BUILD_DIR/wheels:/build" \
    "$DOCKER_IMAGE"

echo ""
echo "============================================================"
echo " BUILD SUCCESSFUL!"
echo " Wheel location: $BUILD_DIR/wheels/"
echo "============================================================"
ls -la "$BUILD_DIR/wheels"/*.whl
echo ""
echo "To install: pip install $BUILD_DIR/wheels/deepspeed-*.whl"
