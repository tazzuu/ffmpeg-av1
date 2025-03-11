FROM ubuntu:24.04

# actually we are using 0b097ed9f141f57e2b91f0704c721a9eff0204c0 because the latest version breaks with AV1 lib
ENV FFMPEG_VERSION=7.1.1
ENV VMAF_VERSION=3.0.0
ENV SVT_AV1_VERSION=v3.0.1
ENV AOM_VERSION=v3.12.0
ENV SOURCE_DIR=/opt/ffmpeg_sources
ENV BUILD_DIR=/opt/ffmpeg_build
ENV BIN_DIR=/opt/bin

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
libdav1d-dev

RUN mkdir -p $SOURCE_DIR $BIN_DIR

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

RUN cd $SOURCE_DIR && \
wget https://github.com/Netflix/vmaf/archive/v$VMAF_VERSION.tar.gz && \
tar xvf v$VMAF_VERSION.tar.gz && \
mkdir -p vmaf-$VMAF_VERSION/libvmaf/build &&\
cd vmaf-$VMAF_VERSION/libvmaf/build && \
meson setup -Denable_tests=false -Denable_docs=false --buildtype=release --default-library=static .. --prefix "$BUILD_DIR" --bindir="$BIN_DIR" --libdir="$BUILD_DIR/lib" && \
ninja -j $(nproc) && \
ninja install -j $(nproc)

# NOTE THE GIT COMMIT USED HERE INSTEAD OF VERSION TAG
# BECAUSE THE 7.1.1 RELEASE KEPT BREAKING ON SOME LIB
RUN cd $SOURCE_DIR && \
git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ffmpeg && \
cd ffmpeg && \
git checkout 0b097ed9f141f57e2b91f0704c721a9eff0204c0 && \
PATH="$BIN_DIR:$PATH" PKG_CONFIG_PATH="$BUILD_DIR/lib/pkgconfig" ./configure \
  --prefix="$BUILD_DIR" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$BUILD_DIR/include" \
  --extra-ldflags="-L$BUILD_DIR/lib" \
  --extra-libs="-lpthread -lm" \
  --ld="g++" \
  --bindir="$BIN_DIR" \
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
  --enable-nonfree && \
PATH="$BIN_DIR:$PATH" make -j $(nproc) && \
make install -j $(nproc) && \
hash -r

ENV PATH=$BIN_DIR:$PATH