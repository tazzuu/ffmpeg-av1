# Usage

Build the container

```bash
docker build -t ffmpeg-av1:7.1.1 .

docker run --rm -ti ffmpeg-av1:7.1.1 ffmpeg --help
```

Run the scripts

```bash
# for CPU based transcoding into AV1
./scripts/ffmpeg_svt-av1.sh input.mkv output.mkv
```

Helpful commands

```bash
# plugin lists
docker run ffmpeg-av1:7.1.1 ffmpeg -encoders | grep -i av1
docker run ffmpeg-av1:7.1.1 ffmpeg -decoders | grep -i av1
docker run ffmpeg-av1:7.1.1 ffmpeg -filters | grep vmaf

# plugin help
docker run ffmpeg-av1:7.1.1 ffmpeg -h filter=libvmaf

# VMAF score
docker run --rm -ti -v $PWD:$PWD --workdir $PWD ffmpeg-av1:7.1.1 ffmpeg -i input.mkv -i input.mkv -lavfi libvmaf -f null -

# get JSON format details of input video
docker run --rm -ti -v $PWD:$PWD --workdir $PWD ffmpeg-av1:7.1.1 ffprobe -i input.mkv -show_streams -show_format -print_format json -hide_banner -v quiet

# test that you can run Nvidia GPU in Docker
docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi

# test that you can run Intel GPU in Docker
docker run --rm --device=/dev/dri:/dev/dri --group-add video ubuntu:24.04 bash -c 'apt update && apt install -y clinfo intel-opencl-icd && clinfo'
```

# Resources

## VMAF

- https://github.com/Netflix/vmaf
- https://github.com/Netflix/vmaf/issues/111
- https://github.com/Netflix/vmaf/blob/master/resource/doc/ffmpeg.md
- https://ottverse.com/vmaf-ffmpeg-ubuntu-compilation-installation-usage-guide/
- https://github.com/Netflix/vmaf/issues/989
- https://github.com/Netflix/vmaf/blob/master/libvmaf/README.md#install
- https://stackoverflow.com/questions/62061410/can-someone-help-me-to-install-the-netflixs-vmaf-library-in-ubuntu

## Nvidia

- https://github.com/FFmpeg/nv-codec-headers
- https://docs.nvidia.com/video-technologies/video-codec-sdk/12.0/ffmpeg-with-nvidia-gpu/index.html
- https://documentation.ubuntu.com/server/how-to/graphics/install-nvidia-drivers/
- https://stackoverflow.com/questions/75661224/building-ffmpeg-with-nvidia-gpu-hardware-acceleration-in-docker-image-cannot-lo
- https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/1.17.0/docker-specialized.html?#driver-capabilities

## AV1

- https://gitlab.com/AOMediaCodec/SVT-AV1/-/blob/master/Docs/Ffmpeg.md
- https://aomedia.googlesource.com/aom
- https://gitlab.com/AOMediaCodec/SVT-AV1/-/releases
- https://github.com/plexguide/tdarr-av1/tree/main

## ffmpeg

- https://ffmpeg.org/download.html
- https://github.com/jellyfin/jellyfin-ffmpeg
- https://trac.ffmpeg.org/wiki/CompilationGuide
- https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
- https://askubuntu.com/questions/1252997/unable-to-compile-ffmpeg-on-ubuntu-20-04
- https://trac.ffmpeg.org/ticket/8810
- https://github.com/FFmpeg/FFmpeg
- https://gist.github.com/Mcamin/b589d1526e25d3fcd72ea74217c8e1fa
- https://ffmpeg.org/ffmpeg.html#Advanced-options
- https://superuser.com/questions/1612982/how-do-i-copy-all-audio-and-subtitle-when-scaling-video-with-ffmpeg

## Intel

- https://github.com/Intel-Media-SDK/MediaSDK/wiki/Intel-media-stack-on-Ubuntu
- https://dgpu-docs.intel.com/driver/client/overview.html
- https://github.com/intel/cartwheel-ffmpeg/issues/286
- https://github.com/intel/libvpl
- https://dgpu-docs.intel.com/driver/client/overview.html
- https://github.com/intel/vpl-gpu-rt
- https://github.com/Syllo/nvtop/issues/363
- https://github.com/returnhappy/tdarr_intel_arc_av1
- https://forum.level1techs.com/t/ffmpeg-av1-encoding-using-intel-arc-gpu-tips/205120

## Docker

- https://docs.docker.com/compose/how-tos/gpu-support/
- https://docs.linuxserver.io/images/docker-jellyfin/#intelatiamd

## Test Videos

- https://github.com/joshuatz/video-test-file-links

## Intel GPU

```bash
# Verify that the GPU is working

# check with clinfo
docker run --rm --device=/dev/dri:/dev/dri --group-add video ubuntu:24.04 bash -c 'apt update && apt install -y clinfo intel-opencl-icd && clinfo'

# get the path to the GPU for Intel ; this can change on reboot
INTEL_PCI_NODE="$(lspci | grep 'VGA compatible controller: Intel Corporation' | cut -d ' ' -f1)"
INTEL_CARD="$(readlink -f /dev/dri/by-path/pci-0000:$INTEL_PCI_NODE-card)"
INTEL_RENDER="$(readlink -f /dev/dri/by-path/pci-0000:$INTEL_PCI_NODE-render)"

# check with vainfo
docker run --rm \
--device=$INTEL_CARD \
--device=$INTEL_RENDER \
--group-add video \
-e LIBVA_DRIVER_NAME=iHD \
-e LIBVA_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri \
-e XDG_RUNTIME_DIR=/tmp \
ffmpeg-av1:7.1.1 vainfo --display drm --device $INTEL_RENDER

```




