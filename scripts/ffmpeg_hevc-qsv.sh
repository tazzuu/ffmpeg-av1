#!/bin/bash
set -euo pipefail

INPUT_FILE="$1"
OUTPUT_FILE="$2"

INPUT_DIR="$(readlink -f $(dirname "$INPUT_FILE"))"

CONTAINER="ffmpeg-av1:7.1.1-intel"
INTEL_PCI_NODE="$(lspci | grep 'VGA compatible controller: Intel Corporation' | cut -d ' ' -f1)"
INTEL_CARD="$(readlink -f /dev/dri/by-path/pci-0000:$INTEL_PCI_NODE-card)"
INTEL_RENDER="$(readlink -f /dev/dri/by-path/pci-0000:$INTEL_PCI_NODE-render)"

set -x
docker run --rm \
--device=$INTEL_CARD \
--device=$INTEL_RENDER \
--group-add video \
-v $PWD:$PWD \
-v $INPUT_DIR:$INPUT_DIR \
-w $PWD \
-e MFX_ACCEL_MODE=VAAPI \
-e MFX_VAAPI_DEVICE=$INTEL_RENDER \
"$CONTAINER" \
ffmpeg -y \
-loglevel verbose \
-i "$INPUT_FILE" \
-init_hw_device vaapi=va:$INTEL_RENDER \
-c:v hevc_qsv -c:a copy -c:s copy "$OUTPUT_FILE"

