################################################################################
# Musl jbuilder from must-cross-make
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

# Install rust and setup default toolchain and target
RUN curl https://sh.rustup.rs -sSf | \
  sh -s -- -y --default-toolchain $TOOLCHAIN && \
  rustup target add $TARGET && \
  echo "[build]\ntarget = \"$TARGET\"\n\n[target.$TARGET]\nlinker = \"$TARGET-gcc\"\n" > $CARGO_HOME/config


ENV CC=$TARGET-gcc
ENV CXX=$TARGET-g++
ENV LD=$TARGET-ld
ENV C_INCLUDE_PATH=$OUTPUT/$TARGET/include

RUN groupadd --system cross && \
  useradd --create-home --system \
  --gid cross --groups sudo --uid 1000 --shell /bin/bash cross;

RUN echo "%sudo ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/nopasswd

USER cross
ENV HOME=/home/cross \
  USER=cross

RUN mkdir /home/cross/project

WORKDIR /home/cross/project
