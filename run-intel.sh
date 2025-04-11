#!/bin/bash
set -euo pipefail

INTEL_PCI_NODE="$(lspci | grep 'VGA compatible controller: Intel Corporation' | cut -d ' ' -f1)"
INTEL_CARD="$(readlink -f /dev/dri/by-path/pci-0000:$INTEL_PCI_NODE-card)"
INTEL_RENDER="$(readlink -f /dev/dri/by-path/pci-0000:$INTEL_PCI_NODE-render)"

set -x
docker run --rm \
--device=$INTEL_CARD \
--device=$INTEL_RENDER \
--group-add video \
-e LIBVA_DRIVER_NAME=iHD \
-e LIBVA_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri \
-e MFX_VAAPI_DEVICE=$INTEL_RENDER \
-e MFX_ACCEL_MODE=VAAPI \
-v $PWD:$PWD \
-w $PWD \
ffmpeg-av1:7.1.1 \
ffmpeg -y \
-i input.mkv \
-c:v av1_qsv \
-preset medium \
-low_power 0 \
-b:v 4M \
-c:a copy \
-c:s copy \
output.mkv