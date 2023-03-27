FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
    && apt-get -y install \
    wget \
    xvfb \
    unzip \
    autoconf \
    automake \
    bison \
    build-essential \
    cmake \
    git \
    meson \
    libtool \
    python3 \
    python3-mako \
    python3-setuptools \
    python3-distutils \
    bison \
    flex \
    dpkg-dev \
    glslang-tools \
    libudev-dev \
    libpciaccess-dev \
    libcairo-dev \
    libclc-15-dev \
    libllvmspirvlib-15-dev \
    llvm \
    llvm-dev \
    wayland-protocols \
    libwayland-dev \
    libx11-dev \
    libxext-dev \
    libxfixes-dev \
    libxcb-glx0-dev \
    libxcb-shm0-dev \
    libxcb1-dev \
    libx11-xcb-dev \
    libxcb-dri2-0-dev \
    libxcb-dri3-dev \
    libxcb-present-dev \
    libxcb-sync-dev \
    libxshmfence-dev \
    x11proto-dev \
    libxxf86vm-dev \
    libxcb-xfixes0-dev \
    libxcb-randr0-dev \
    libxrandr-dev \
    xz-utils \
    x11vnc \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ARG S6_OVERLAY_VERSION=3.1.4.1
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp

RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz

ARG MESA_VERSION=22.2.0
RUN set -xe; \
    mkdir -p /var/tmp/build; \
    cd /var/tmp/build/; \
    git clone --depth=1 --branch=mesa-${MESA_VERSION} https://gitlab.freedesktop.org/mesa/mesa.git;

RUN set -xe; \
    mkdir -p /var/tmp/build; \
    cd /var/tmp/build/; \
    git clone --depth=1 --branch=main https://gitlab.freedesktop.org/mesa/drm.git

RUN set -xe; \
    cd /var/tmp/build/drm; \
    meson \
        --buildtype=plain \
        --prefix=/usr/local \
        --sysconfdir=/etc \
        -Dvalgrind=disabled \
        -Db_ndebug=true \
        -Dtests=false  \
        build/; \
    ninja -C build/ -j $(getconf _NPROCESSORS_ONLN); \
    ninja -C build/ install;

RUN set -xe; \
    cd /var/tmp/build/mesa; \
    libtoolize; \
    meson \
        --buildtype=release \
        --prefix=/usr/local \
        --sysconfdir=/etc \
        -D b_ndebug=true \
        -D egl=true \
        -D gallium-nine=false \
        -D gbm=true \
        -D gles1=false \
        -D gles2=true \
        -D opengl=true \
        -D dri-drivers-path=/usr/local/lib/xorg/modules/dri \
        -D dri-drivers= \
        -D dri3=true  \
        -D egl=false \
        -D gallium-drivers="swrast" \
        -D gbm=false \
        -D glx=dri \
        -D llvm=true \
        -D lmsensors=false \
        -D optimization=3 \
        -D osmesa=true  \
        -D platforms=x11,wayland \
        -D shared-glapi=true \
        -D shared-llvm=true \
        -D vulkan-drivers= \
        build/; \
    ninja -C build/ -j $(getconf _NPROCESSORS_ONLN); \
    ninja -C build/ install;

RUN rm -f /var/tmp/build 

COPY root / 

ENTRYPOINT ["/init", "xvfb-run", "--listen-tcp", "-f", "/tmp/xvfb-run"]