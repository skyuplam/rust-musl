################################################################################
# Musl builder from must-cross-make
################################################################################
From debian:stretch AS muslmaker
LABEL maintainer="Terrence Lam <skyuplam@gmail.com>"

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  file \
  curl \
  xutils-dev

COPY musl-cross-make/ /src/
COPY config.mak /src/

WORKDIR /src

ARG TARGET=arm-unknown-linux-musleabihf
ARG OUTPUT=/usr/local/musl

RUN make -j"$(nproc)" TARGET=$TARGET && \
  make -j"$(nproc)" TARGET=$TARGET OUTPUT=$OUTPUT install


################################################################################
# Rust
################################################################################
From debian:stretch
LABEL maintainer="Terrence Lam <skyuplam@gmail.com>"

ARG TARGET=arm-unknown-linux-musleabihf
ARG OUTPUT=/usr/local/musl

COPY --from=muslmaker $OUTPUT $OUTPUT

# Set default toolchain
ARG TOOLCHAIN=stable

# Rust Env var
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  file \
  git \
  curl \
  pkgconf \
  xutils-dev \
  sudo && \
  apt-get clean && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*


ENV PATH=/usr/local/bin:/usr/local/cargo/bin:/usr/local/rustup/bin:$PATH
ENV PATH=$OUTPUT/bin:$PATH
ENV C_INCLUDE_PATH=$OUTPUT/$TARGET/include

# Install rust and setup default toolchain and target
RUN curl https://sh.rustup.rs -sSf | \
  sh -s -- -y --default-toolchain $TOOLCHAIN && \
  rustup target add $TARGET && \
  echo "[build]\ntarget = \"$TARGET\"\n\n[target.$TARGET]\nlinker = \"$TARGET-gcc\"\n" > $CARGO_HOME/config


ENV CC=$TARGET-gcc
ENV CXX=$TARGET-g++
ENV LD=$TARGET-ld
ENV AS=$TARGET-as
ENV AR=$TARGET-ar

# Install zlib
ARG ZLIB_VER=1.2.11
ARG ZLIB_SHA256_CHECKSUM=c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1

RUN curl -sqO http://zlib.net/zlib-$ZLIB_VER.tar.gz && \
  echo $ZLIB_SHA256_CHECKSUM zlib-$ZLIB_VER.tar.gz | sha256sum -c - && \
  tar xzf zlib-$ZLIB_VER.tar.gz && \
  cd zlib-$ZLIB_VER && \
  ./configure --static --archs="-fPIC" --prefix=$OUTPUT/$TARGET && \
  make -j"$(nproc)" && make -j"$(nproc)" install && \
  cd .. && rm -rf zlib-$ZLIB_VER.tar.gz zlib-$ZLIB_VER

ARG SSL_VER=1.1.0i
ARG SSL_ARCH=linux-generic32

RUN curl -sSO https://www.openssl.org/source/openssl-$SSL_VER.tar.gz && \
    curl -sSL https://www.openssl.org/source/openssl-$SSL_VER.tar.gz.sha256 | \
      sed 's@$@ openssl-'$SSL_VER'.tar.gz@' | sha256sum -c - && \
    tar xzf openssl-$SSL_VER.tar.gz && \
    cd openssl-$SSL_VER && \
    ./Configure $SSL_ARCH no-shared no-async -fPIC \
    --prefix=$OUTPUT/$TARGET \
    --openssldir=$OUTPUT/$TARGET/ssl && \
    make depend 2> /dev/null && \
    make -j$(nproc) && make -j$(nproc) install && \
    cd .. && rm -rf openssl-$SSL_VER*

RUN groupadd --system cross && \
  useradd --create-home --system \
  --gid cross --groups sudo --uid 1000 --shell /bin/bash cross;

RUN echo "%sudo ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/nopasswd

USER cross
ENV HOME=/home/cross \
  USER=cross

RUN mkdir /home/cross/project

WORKDIR /home/cross/project
