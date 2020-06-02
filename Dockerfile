################################################################################
# Builder
################################################################################
From debian:stretch AS muslmaker
LABEL maintainer="Terrence Lam <skyuplam@gmail.com>"

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  file \
  curl \
  xutils-dev

ARG TARGET=arm-unknown-linux-musleabihf
ARG OUTPUT=/usr/local/musl

COPY musl-cross-make/ /src/
COPY common-config.mak /src/common-config.mak
COPY $TARGET-config.mak /src/$TARGET-config.mak

# musl-cross-make make config
RUN cat /src/*.mak > /src/config.mak

WORKDIR /src

RUN nice make -j"$(nproc)" TARGET=$TARGET && \
  nice make -j"$(nproc)" TARGET=$TARGET OUTPUT=$OUTPUT install

# Setting up Env vars
ENV PATH=$OUTPUT/bin:/usr/local/bin:$PATH \
  C_INCLUDE_PATH=$OUTPUT/$TARGET/include \
  CC=$TARGET-gcc \
  CXX=$TARGET-g++ \
  LD=$TARGET-ld \
  AS=$TARGET-as \
  AR=$TARGET-ar

# Install zlib
ARG ZLIB_VER=1.2.11
ARG ZLIB_SHA256_CHECKSUM=c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1

RUN curl -sqO http://zlib.net/zlib-$ZLIB_VER.tar.gz && \
  echo $ZLIB_SHA256_CHECKSUM zlib-$ZLIB_VER.tar.gz | sha256sum -c - && \
  tar xzf zlib-$ZLIB_VER.tar.gz && \
  cd zlib-$ZLIB_VER && \
  ./configure --static --archs="-fPIC" --prefix=$OUTPUT/$TARGET && \
  nice make -j"$(nproc)" && nice make -j"$(nproc)" install && \
  cd .. && rm -rf zlib-$ZLIB_VER.tar.gz zlib-$ZLIB_VER

# Install OpenSSL
ARG SSL_VER=1.1.1g
ARG SSL_ARCH=linux-armv4

RUN curl -sSO https://www.openssl.org/source/openssl-$SSL_VER.tar.gz && \
  curl -sSL https://www.openssl.org/source/openssl-$SSL_VER.tar.gz.sha256 | \
    sed 's@$@ openssl-'$SSL_VER'.tar.gz@' | sha256sum -c - && \
  tar xzf openssl-$SSL_VER.tar.gz && \
  cd openssl-$SSL_VER && \
  ./Configure $SSL_ARCH no-shared no-async -fPIC \
  --prefix=$OUTPUT/$TARGET \
  --openssldir=$OUTPUT/$TARGET/ssl && \
  nice make depend 2> /dev/null && \
  nice make -j$(nproc) && nice make -j$(nproc) install && \
  cd .. && rm -rf openssl-$SSL_VER*


################################################################################
# Rust
################################################################################
From debian:stretch
LABEL maintainer="Terrence Lam <skyuplam@gmail.com>"

ARG TARGET=arm-unknown-linux-musleabihf
ARG OUTPUT=/usr/local/musl

COPY --from=muslmaker $OUTPUT $OUTPUT

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  file \
  git \
  curl \
  xutils-dev \
  cmake \
  sudo && \
  apt-get clean && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

ENV HOME=/home/cross \
  USER=cross

# Add user `cross`
RUN groupadd --system $USER && \
  useradd --create-home --system \
  --gid cross --groups sudo --uid 1000 --shell /bin/bash $USER;
# Add user `cross` to sudoers
RUN echo "%sudo ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/nopasswd

USER cross

WORKDIR /home/cross

# Rustup and cargo Env var
ENV RUSTUP_HOME=$HOME/.rustup \
    CARGO_HOME=$HOME/.cargo
ENV PATH=$OUTPUT/bin:/usr/local/bin:$CARGO_HOME/bin:$RUSTUP_HOME/bin:$PATH

# Set default toolchain
ARG TOOLCHAIN=stable

# Install rust and setup default toolchain and target
RUN curl https://sh.rustup.rs -sSf | \
  sh -s -- -y --default-toolchain $TOOLCHAIN && \
  rustup target add $TARGET && \
  echo "[target.$TARGET]\nlinker = \"$TARGET-gcc\"" > $CARGO_HOME/config && \
  echo "[build]\ntarget = \"$TARGET\"\n" >> $CARGO_HOME/config

RUN mkdir /home/$USER/project

# Other Env vars
ENV C_INCLUDE_PATH=$OUTPUT/$TARGET/include \
  CC=$TARGET-gcc \
  CXX=$TARGET-g++ \
  CC_$TARGET=$TARGET-gcc \
  CXX_$TARGET=$TARGET-g++ \
  LD=$TARGET-ld \
  AS=$TARGET-as \
  AR=$TARGET-ar \
  OPENSSL_DIR=$OUTPUT/$TARGET \
  OPENSSL_INCLUDE_DIR=$OUTPUT/$TARGET/include \
  DEP_OPENSSL_INCLUDE=$OUTPUT/$TARGET/include \
  OPENSSL_LIB_DIR=$OUTPUT/$TARGET/lib \
  OPENSSL_STATIC=1 \
  LIBZ_SYS_STATIC=1 \
  RUST_TEST_THREADS=1

WORKDIR /home/$USER/project
