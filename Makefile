REPOSITORY = skyuplam/rust-musl-armhf

# Target for [`musl-cross-make`](https://github.com/richfelker/musl-cross-make#supported-targets)
# see also `$ rustup target list` and make sure it's supported by
# `musl-cross-make`
TARGET=arm-unknown-linux-musleabihf
# Output location for `musl-cross-make`
OUTPUT=/usr/local/musl
# Rustup toolchain
TOOLCHAIN=stable

# zlib
ZLIB_VER=1.2.11
ZLIB_SHA256_CHECKSUM=c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1
# openssl
SSL_VER=1.1.1a
SSL_ARCH=linux-generic32


# Build docker image
build:
	docker build \
			--build-arg TARGET=$(TARGET) \
			--build-arg OUTPUT=$(OUTPUT) \
			--build-arg TOOLCHAIN=$(TOOLCHAIN) \
			--build-arg ZLIB_VER=$(ZLIB_VER) \
			--build-arg ZLIB_SHA256_CHECKSUM=$(ZLIB_SHA256_CHECKSUM) \
			--build-arg SSL_VER=$(SSL_VER) \
			--build-arg SSL_ARCH=$(SSL_ARCH) \
			-t $(REPOSITORY):$(TARGET) .
.PHONY: build

# Push the built docker image to docker hub
push:
	docker push $(REPOSITORY):$(TARGET)
.PHONY: push

# Build and push docker image arm-unknown-linux-musleabihf
arm:
	make TARGET=arm-unknown-linux-musleabihf build && \
			make TARGET=arm-unknown-linux-musleabihf push
.PHONY: arm

# Build and push docker image armv7-unknown-linux-musleabihf
armv7:
	make TARGET=armv7-unknown-linux-musleabihf build && \
			make TARGET=armv7-unknown-linux-musleabihf push
.PHONY: armv7
