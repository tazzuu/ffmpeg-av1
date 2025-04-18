FROM ubuntu:24.04

# ENV FFMPEG_VERSION=7.1.1
ENV FFMPEG_VERSION=7684243fbe6e84fecb4a039195d5fda8a006a2a4
ENV VMAF_VERSION=3.0.0
ENV SVT_AV1_VERSION=v3.0.1
ENV AOM_VERSION=v3.12.0
ENV SOURCE_DIR=/opt/ffmpeg_sources
ENV BUILD_DIR=/opt/ffmpeg_build
ENV BIN_DIR=/opt/bin
ENV NV_CODEC_VERSION=n13.0.19.0

RUN apt update && apt upgrade -y

RUN apt -y install \
autoconf \
automake \
build-essential \
cmake \
git-core \
libass-dev \
libfreetype6-dev \
libgnutls28-dev \
libunistring-dev \
libmp3lame-dev \
libsdl2-dev \
libtool \
libva-dev \
libvdpau-dev \
libvorbis-dev \
libxcb1-dev \
libxcb-shm0-dev \
libxcb-xfixes0-dev \
meson \
ninja-build \
pkg-config \
texinfo \
wget \
yasm \
zlib1g-dev \
nasm \
libx264-dev \
libx265-dev libnuma-dev \
libvpx-dev \
libfdk-aac-dev \
libopus-dev \
libdav1d-dev \
libmfx-gen1.2 libmfx-tools \
libva-drm2 libva-x11-2 libva-wayland2 libva-glx2 vainfo intel-media-va-driver-non-free \
i965-va-driver \
software-properties-common \
libvpl-dev \
xxd \
libc6 libc6-dev unzip libnuma1

RUN mkdir -p $SOURCE_DIR $BIN_DIR

# AV1 libraries
RUN cd $SOURCE_DIR && \
git -C aom pull 2> /dev/null || git clone --depth 1 --branch $AOM_VERSION https://aomedia.googlesource.com/aom && \
mkdir -p aom_build && \
cd aom_build && \
PATH="$BIN_DIR:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$BUILD_DIR" -DENABLE_TESTS=OFF -DENABLE_NASM=on ../aom && \
PATH="$BIN_DIR:$PATH" make -j $(nproc) && \
make install -j $(nproc)

RUN cd $SOURCE_DIR && \
git -C SVT-AV1 pull 2> /dev/null || git clone --branch $SVT_AV1_VERSION https://gitlab.com/AOMediaCodec/SVT-AV1.git && \
mkdir -p SVT-AV1/build && \
cd SVT-AV1/build && \
PATH="$BIN_DIR:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release -DBUILD_DEC=OFF -DBUILD_SHARED_LIBS=OFF .. && \
PATH="$BIN_DIR:$PATH" make -j $(nproc) && \
make install -j $(nproc)

# VMAF library
RUN cd $SOURCE_DIR && \
wget https://github.com/Netflix/vmaf/archive/v$VMAF_VERSION.tar.gz && \
tar xvf v$VMAF_VERSION.tar.gz && \
mkdir -p vmaf-$VMAF_VERSION/libvmaf/build &&\
cd vmaf-$VMAF_VERSION/libvmaf/build && \
meson setup -Denable_tests=false -Denable_docs=false --buildtype=release --default-library=static .. --prefix "$BUILD_DIR" --bindir="$BIN_DIR" --libdir="$BUILD_DIR/lib" && \
ninja -j $(nproc) && \
ninja install -j $(nproc)

# Nvidia libraries
# This is the official URL but its constantly down https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
RUN cd $SOURCE_DIR && \
git clone --depth 1 --branch "$NV_CODEC_VERSION" https://github.com/FFmpeg/nv-codec-headers.git && \
cd nv-codec-headers && make install -j $(nproc)

RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb && \
dpkg -i cuda-keyring_1.1-1_all.deb && \
apt update && apt install -y cuda-toolkit nvidia-cuda-toolkit

# ffmpeg
# # NOTE THE GIT COMMIT USED HERE INSTEAD OF VERSION TAG
# # BECAUSE THE 7.1.1 RELEASE KEPT BREAKING ON SOME LIB
# NOTE: the repo is huge so we need to take drastic measures to not clone the whole thing
# while also keeping our Dockerfile pinned to a specific version
RUN cd $SOURCE_DIR && \
git init ffmpeg && \
cd ffmpeg && \
git remote add origin https://github.com/FFmpeg/FFmpeg.git && \
git fetch --depth=1 origin "$FFMPEG_VERSION" && \
git checkout "$FFMPEG_VERSION" && \
PATH="$BIN_DIR:$PATH" PKG_CONFIG_PATH="$BUILD_DIR/lib/pkgconfig" ./configure \
  --prefix="$BUILD_DIR" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$BUILD_DIR/include" \
  --extra-ldflags="-L$BUILD_DIR/lib" \
  --extra-libs="-lpthread -lm" \
  --ld="g++" \
  --bindir="$BIN_DIR" \
  --enable-cuda-nvcc \
  --enable-nvdec \
  --enable-nvenc \
  --enable-cuvid \
  --enable-cuda \
  --enable-ffnvcodec \
  --enable-libnpp \
  --extra-cflags=-I/usr/local/cuda/include \
  --extra-ldflags=-L/usr/local/cuda/lib64 \
  --enable-libvmaf \
  --enable-gpl \
  --enable-gnutls \
  --enable-libaom \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libsvtav1 \
  --enable-libdav1d \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpl \
  --enable-version3 \
  --enable-nonfree && \
PATH="$BIN_DIR:$PATH" make -j $(nproc) && \
make install -j $(nproc) && \
hash -r

# NOTE:
# --enable-libmfx \
# can not use libmfx and libvpl together

ENV PATH=$BIN_DIR:$PATH