#!/bin/bash
set -euxo pipefail

docker run --rm --runtime=nvidia --gpus all -e NVIDIA_DRIVER_CAPABILITIES=video ffmpeg-av1:7.1.1 clinfo

docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi