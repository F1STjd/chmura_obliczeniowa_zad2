# ================================================================================
# Multi-Architecture Dockerfile for C++ Weather Application
# ================================================================================
# Optymalizowany Dockerfile obsługujący budowanie dla linux/amd64 i linux/arm64
# Wykorzystuje Docker Buildx do cross-compilation i budowania multi-arch images

# ----------------
# Stage 1: build
# ----------------
FROM alpine:3.21 AS builder

# Instalacja zależności kompilacji z obsługą cross-compilation
RUN apk add --no-cache \
      build-base \
      cmake \
      git \
      linux-headers \
      musl-dev \
      openssl-libs-static \
      libstdc++-dev \
      # Dodatkowo dla multi-arch
      gcc-aarch64-none-elf \
      gcc-x86_64-linux-gnu

# Argumenty build-time dla obsługi różnych architektur
ARG TARGETPLATFORM
ARG TARGETOS  
ARG TARGETARCH

WORKDIR /src

# Kopiowanie kodu źródłowego i plików konfiguracyjnych
COPY CMakeLists.txt main.cpp ./

# Build static fmt library z obsługą cross-compilation
RUN git clone --depth 1 https://github.com/fmtlib/fmt.git \
  && mkdir fmt/build && cd fmt/build \
  && cmake -DCMAKE_BUILD_TYPE=MinSizeRel \
           -DBUILD_SHARED_LIBS=OFF \
           -DCMAKE_INSTALL_PREFIX=/usr \
           -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
           .. \
  && make -j$(nproc) install

# Instalacja httplib (header-only library)
RUN git clone --depth 1 https://github.com/yhirose/cpp-httplib.git \
  && cp -R cpp-httplib /usr/include/httplib

# Build aplikacji z maksymalną optymalizacją rozmiaru i statycznym linkowaniem
WORKDIR /src
RUN mkdir build && cd build \
  && cmake \
       -DCMAKE_BUILD_TYPE=MinSizeRel \
       -DBUILD_SHARED_LIBS=OFF \
       -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
       -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
       -DCMAKE_C_FLAGS="-Oz -ffunction-sections -fdata-sections -fvisibility=hidden -flto" \
       -DCMAKE_CXX_FLAGS="-Oz -ffunction-sections -fdata-sections -fvisibility=hidden -flto -fno-rtti" \
       -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++ \
        -Wl,--gc-sections -s \
        -Wl,--build-id=none \
        -Wl,--strip-all -Wl,--as-needed" \
       .. \
  && make -j$(nproc)

# Strip symboli debugowania dla minimalnego rozmiaru
RUN strip build/bin/main

# --------------------------------
# Stage 2: Minimal runtime image
# --------------------------------
FROM scratch

# Metadane obrazu
LABEL org.opencontainers.image.title="Weather Application" \
      org.opencontainers.image.description="Minimal C++ weather application with web interface" \
      org.opencontainers.image.author="Konrad Nowak" \
      org.opencontainers.image.source="https://github.com/username/repo" \
      org.opencontainers.image.licenses="MIT"

# Kopiowanie statycznie skompilowanego pliku wykonywalnego
COPY --from=builder /src/build/bin/main /app/weather

# Port aplikacji
EXPOSE 3000

# Punkt wejścia aplikacji
ENTRYPOINT ["/app/weather"]
  