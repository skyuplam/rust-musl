REPOSITORY = skyuplam/rust-musl-armhf

TARGET=arm-linux-musleabihf
OUTPUT=/usr/local/musl
TOOLCHAIN=stable
RUST_TARGET=arm-unknown-linux-musleabihf


build:
	docker build \
			--build-arg TARGET=$(TARGET) \
			--build-arg OUTPUT=$(OUTPUT) \
			--build-arg TOOLCHAIN=$(TOOLCHAIN) \
			--build-arg RUST_TARGET=$(RUST_TARGET) \
			-t $(REPOSITORY):latest .
.PHONY: build

push:
	docker push $(REPOSITORY):latest
.PHONY: push
