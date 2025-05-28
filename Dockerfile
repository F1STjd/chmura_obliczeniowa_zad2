# syntax=docker/dockerfile:1.4

############################
# Stage 1: Build (Multi-arch)
############################
FROM --platform=$BUILDPLATFORM ubuntu:24.04 AS builder

# Install newer GCC and dependencies
RUN --mount=type=cache,target=/var/lib/apt,id=apt \
    apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        software-properties-common && \
    add-apt-repository ppa:ubuntu-toolchain-r/test && \
    apt-get update && apt-get install -y --no-install-recommends \        build-essential \
        gcc-14 \
        g++-14 \
        cmake \
        make \
        ninja-build \
        git \
        pkg-config \
        libssl-dev \
        libz-dev && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY CMakeLists.txt main.cpp ./
COPY cpp-httplib/ ./cpp-httplib/

RUN git clone --depth 1 https://github.com/fmtlib/fmt.git && \
    cd fmt && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=MinSizeRel \
          -DBUILD_SHARED_LIBS=OFF \
          -DCMAKE_INSTALL_PREFIX=/usr . && \
    cmake --build . --target install && \
    cd .. && rm -rf fmt

RUN cmake -G Ninja -S . -B build \
          -DCMAKE_BUILD_TYPE=MinSizeRel \
          -DCMAKE_C_FLAGS="-Os -ffunction-sections -fdata-sections -fvisibility=hidden" \
          -DCMAKE_CXX_FLAGS="-Os -ffunction-sections -fdata-sections -fvisibility=hidden -fno-rtti" \
          -DCMAKE_EXE_LINKER_FLAGS="-Wl,--gc-sections -Wl,--build-id=none -Wl,--strip-all -Wl,--as-needed" && \
    cmake --build build --parallel && \
    strip build/bin/main

############################
# Stage 2: Runtime Image
############################
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
        libssl3 \
        zlib1g \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/build/bin/main /app/weather

EXPOSE 3000
ENTRYPOINT ["/app/weather"]
