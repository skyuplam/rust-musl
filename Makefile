REPOSITORY = skyuplam/rust-musl-armhf

TARGET=arm-linux-musleabihf
OUTPUT=/opt/$(TARGET)
TOOLCHAIN=stable
RUST_TARGET=arm-unknown-linux-musleabihf


build:
	docker build -t $(REPOSITORY):latest .
.PHONY: build

push:
	docker push $(REPOSITORY):latest
.PHONY: push
