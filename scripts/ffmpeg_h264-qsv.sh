#!/bin/bash
set -euo pipefail

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
-w $PWD \
-e MFX_ACCEL_MODE=VAAPI \
-e MFX_VAAPI_DEVICE=$INTEL_RENDER \
"$CONTAINER" \
ffmpeg -y \
-loglevel verbose \
-i input.mkv \
-init_hw_device vaapi=va:$INTEL_RENDER \
-c:v h264_qsv -c:a copy -c:s copy output.mkv

