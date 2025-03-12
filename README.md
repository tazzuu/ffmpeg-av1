# Usage

Build the container

```bash
docker build -t ffmpeg-av1:7.1.1 .

docker run --rm -ti ffmpeg-av1:7.1.1 ffmpeg --help
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
docker run --rm -ti -v $PWD:$PWD --workdir $PWD ffmpeg-av1:7.1.1 ffmpeg -i data/sample__240__libx264__aac__30s__video.mkv -i data/sample__240__libx264__aac__30s__video.mkv -lavfi libvmaf -f null -
```

# Resources

- https://ffmpeg.org/download.html
- https://stackoverflow.com/questions/62061410/can-someone-help-me-to-install-the-netflixs-vmaf-library-in-ubuntu
- https://trac.ffmpeg.org/wiki/CompilationGuide
- https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
- https://askubuntu.com/questions/1252997/unable-to-compile-ffmpeg-on-ubuntu-20-04
- https://trac.ffmpeg.org/ticket/8810
- https://aomedia.googlesource.com/aom
- https://gitlab.com/AOMediaCodec/SVT-AV1/-/releases
- https://github.com/Netflix/vmaf
- https://github.com/FFmpeg/FFmpeg
- https://github.com/Intel-Media-SDK/MediaSDK/wiki/Intel-media-stack-on-Ubuntu
- https://dgpu-docs.intel.com/driver/client/overview.html
- https://github.com/intel/cartwheel-ffmpeg/issues/286
- https://github.com/Netflix/vmaf/issues/111
- https://github.com/Netflix/vmaf/blob/master/resource/doc/ffmpeg.md
- https://ottverse.com/vmaf-ffmpeg-ubuntu-compilation-installation-usage-guide/
- https://github.com/Netflix/vmaf/issues/989
- https://github.com/Netflix/vmaf/blob/master/libvmaf/README.md#install
- https://gist.github.com/Mcamin/b589d1526e25d3fcd72ea74217c8e1fa
- https://docs.nvidia.com/video-technologies/video-codec-sdk/12.0/ffmpeg-with-nvidia-gpu/index.html
- https://github.com/FFmpeg/nv-codec-headers