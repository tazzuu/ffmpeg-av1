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
-v $PWD:$PWD \
-w $PWD \
-e MFX_ACCEL_MODE=VAAPI \
-e MFX_VAAPI_DEVICE=$INTEL_RENDER \
ffmpeg-av1:7.1.1 \
ffmpeg -y \
-loglevel verbose \
-i input.mkv \
-init_hw_device vaapi=va:$INTEL_RENDER \
-c:v av1_qsv -c:a copy -c:s copy output.mkv
# -c:v hevc_qsv -c:a copy -c:s copy output.mkv

# -c:v hevc_qsv \

# -c:v av1_qsv \
# -c:a copy \
# -c:s copy \
# -preset veryslow \
# -look_ahead_depth 99 \
# -b:v 1M \
# -low_power 0 \
# output.mkv

# -preset medium \
# -low_power 0 \
# -b:v 4M \

# -e LIBVA_DRIVER_NAME=iHD \
# -e LIBVA_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri \

#
