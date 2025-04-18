FROM ubuntu:24.04

# actually we are using 0b097ed9f141f57e2b91f0704c721a9eff0204c0 because the latest version breaks with AV1 lib
# ENV FFMPEG_VERSION=7.1.1
ENV FFMPEG_VERSION=7684243fbe6e84fecb4a039195d5fda8a006a2a4
ENV SOURCE_DIR=/opt/ffmpeg_sources
ENV BUILD_DIR=/opt/ffmpeg_build
ENV BIN_DIR=/opt/bin

RUN mkdir -p $SOURCE_DIR $BIN_DIR
ENV PATH=$BIN_DIR:$PATH

RUN apt update && apt upgrade -y
RUN apt -y install \
build-essential \
git-core \
i965-va-driver \
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
libfdk-aac-dev \
libopus-dev \
libvpl-dev \
libx264-dev \
libx265-dev \
libnuma-dev \
libvpx-dev \
libfdk-aac-dev \
libopus-dev \
libmfx-gen1.2 libmfx-tools \
libva-drm2 libva-x11-2 libva-wayland2 libva-glx2 vainfo intel-media-va-driver-non-free \
nasm \
wget

# Intel drivers
# https://dgpu-docs.intel.com/driver/client/overview.html
RUN wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | \
  gpg --yes --dearmor --output /usr/share/keyrings/intel-graphics.gpg
RUN echo \
  "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu noble unified" | \
  tee /etc/apt/sources.list.d/intel-gpu-noble.list
RUN apt update && apt-get install -y libze-intel-gpu1 libze1 intel-opencl-icd clinfo intel-gsc libze-dev intel-ocloc

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
  --enable-gpl \
  --enable-gnutls \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
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

