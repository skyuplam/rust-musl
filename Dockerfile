################################################################################
# Musl jbuilder from must-cross-make
################################################################################
From debian:stretch AS muslmaker
LABEL maintainer="Terrence Lam <skyuplam@gmail.com>"

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  file \
  git \
  curl \
  wget \
  pkgconf \
  xutils-dev

COPY musl-cross-make/ /src/

WORKDIR /src

ARG TARGET=arm-linux-musleabihf
ARG OUTPUT=/opt/$TARGET

RUN make -j"$(nproc)" TARGET=$TARGET && \
  make -j"$(nproc)" TARGET=$TARGET OUTPUT=$OUTPUT install


################################################################################
# Rust
################################################################################
From debian:stretch
LABEL maintainer="Terrence Lam <skyuplam@gmail.com>"

COPY --from=muslmaker /opt/$TARGET /opt/$TARGET

# Set default toolchain
ARG TOOLCHAIN=stable
ARG RUST_TARGET=arm-unknown-linux-musleabihf

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
ENV PATH=/opt/$TARGET/bin:$PATH

# Install rust and setup default toolchain and target
RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- -y --default-toolchain $TOOLCHAIN && \
    rustup target add $RUST_TARGET && \
    echo "[build]\ntarget = \""$RUST_TARGET"\"" > $CARGO_HOME/config


ENV CC=$TARGET-gcc
ENV CXX=$TARGET-g++
ENV LD=$TARGET-ld

RUN groupadd --system cross && \
  useradd --create-home --system --gid cross --uid 1000 cross;

USER cross
ENV HOME=/home/cross

WORKDIR /home/cross
