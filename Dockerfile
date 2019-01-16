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

COPY musl-cross-make/ /src/
COPY config.mak /src/

WORKDIR /src

ARG TARGET=arm-unknown-linux-musleabihf
ARG OUTPUT=/usr/local/musl

RUN make -j"$(nproc)" TARGET=$TARGET && \
  make -j"$(nproc)" TARGET=$TARGET OUTPUT=$OUTPUT install

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


################################################################################
# Rust
################################################################################
From debian:stretch
LABEL maintainer="Terrence Lam <skyuplam@gmail.com>"

ARG TARGET=arm-unknown-linux-musleabihf
ARG OUTPUT=/usr/local/musl

COPY --from=muslmaker $OUTPUT $OUTPUT

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  file \
  git \
  curl \
  xutils-dev \
  sudo && \
  apt-get clean && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Add user `cross`
RUN groupadd --system cross && \
  useradd --create-home --system \
  --gid cross --groups sudo --uid 1000 --shell /bin/bash cross;
# Add user `cross` to sudoers
RUN echo "%sudo ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/nopasswd

USER cross

ENV HOME=/home/cross \
  USER=cross
WORKDIR /home/cross

# Rustup and cargo Env var
ENV RUSTUP_HOME=$HOME/.rustup \
    CARGO_HOME=$HOME/.cargo

# Other Env vars
ENV PATH=$OUTPUT/bin:/usr/local/bin:$CARGO_HOME/bin:$RUSTUP_HOME/bin:$PATH \
  C_INCLUDE_PATH=$OUTPUT/$TARGET/include \
  CC=$TARGET-gcc \
  CXX=$TARGET-g++ \
  LD=$TARGET-ld \
  AS=$TARGET-as \
  AR=$TARGET-ar \
  OPENSSL_DIR=$OUTPUT/$TARGET \
  OPENSSL_INCLUDE_DIR=$OUTPUT/$TARGET/include \
  DEP_OPENSSL_INCLUDE=$OUTPUT/$TARGET/include \
  OPENSSL_LIB_DIR=$OUTPUT/$TARGET/lib \
  OPENSSL_STATIC=1 \
  LIBZ_SYS_STATIC=1

# Set default toolchain
ARG TOOLCHAIN=stable

# Install rust and setup default toolchain and target
RUN curl https://sh.rustup.rs -sSf | \
  sh -s -- -y --default-toolchain $TOOLCHAIN && \
  rustup target add $TARGET && \
  echo "[target.$TARGET]\nlinker = \"$TARGET-gcc\"" > $CARGO_HOME/config && \
  echo "ar = \"$TARGET-ar\"\n" >> $CARGO_HOME/config && \
  echo "[build]\ntarget = \"$TARGET\"\n" >> $CARGO_HOME/config

RUN mkdir /home/cross/project

WORKDIR /home/cross/project
