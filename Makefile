REPOSITORY = skyuplam/rust-musl-armhf

# Target for [`musl-cross-make`](https://github.com/richfelker/musl-cross-make#supported-targets)
# see also `$ rustup target list` and make sure it's supported by
# `musl-cross-make`
TARGET=arm-unknown-linux-musleabihf
# Output location for `musl-cross-make`
OUTPUT=/usr/local/musl
# Rustup toolchain
TOOLCHAIN=stable

# Build docker image
build:
	docker build \
			--build-arg TARGET=$(TARGET) \
			--build-arg OUTPUT=$(OUTPUT) \
			--build-arg TOOLCHAIN=$(TOOLCHAIN) \
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
