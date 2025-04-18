#!/bin/bash
set -euo pipefail

# https://github.com/intel/cartwheel-ffmpeg/issues/322

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
-hwaccel vaapi -vaapi_device $INTEL_RENDER \
-i "$INPUT_FILE" \
-vf 'format=nv12,hwupload' \
-c:v av1_vaapi -b:v 4M \
-c:a copy \
"$OUTPUT_FILE"









# -init_hw_device vaapi=va:$INTEL_RENDER \
# -c:v av1_qsv -c:a copy -c:s copy "$OUTPUT_FILE"

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
