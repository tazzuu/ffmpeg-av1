#!/bin/bash
set -euxo pipefail

# get the path to the GPU for Intel ; this can change on reboot
INTEL_PCI_NODE="$(lspci | grep 'VGA compatible controller: Intel Corporation' | cut -d ' ' -f1)"
INTEL_CARD="$(readlink -f /dev/dri/by-path/pci-0000:$INTEL_PCI_NODE-card)"
INTEL_RENDER="$(readlink -f /dev/dri/by-path/pci-0000:$INTEL_PCI_NODE-render)"

# check with vainfo for VA-API
docker run --rm \
--device=$INTEL_CARD \
--device=$INTEL_RENDER \
--group-add video \
-e LIBVA_DRIVER_NAME=iHD \
-e LIBVA_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri \
-e XDG_RUNTIME_DIR=/tmp \
ffmpeg-av1:7.1.1 vainfo --display drm --device $INTEL_RENDER

# check for OpenCL
docker run --rm --device=/dev/dri:/dev/dri --group-add video ffmpeg-av1:7.1.1 clinfo