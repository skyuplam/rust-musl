# Cross compilation environment for `rust` targeting [musl](https://www.musl-libc.org/) on ARMHF

Based on the official [Debian stretch](https://github.com/sensorfu/rust-musl-arm.git) image and
[musl-cross-make](https://github.com/richfelker/musl-cross-make) tool to build a
rust cross-compilation development environment.

# Usage

1. Pull the docker image from docker hub

```
$ docker pull skyuplam/rust-musl-armha:latest
```

2. Cross compile using the docker image

```
$ docker run --rm \
  --volume <path to your rust project>:/home/cross/project \
  --volume <path to your local cargo registry, e.g. ~/.cargo/registry>:/usr/local/cargo/registry \ # optional, advoid cargo to update on every build
  skyuplam/rust-musl-armhf:latest \
  <cargo command> # e.g. `cargo build --release`
```

# Build your own docker image

Change the variables in the `Makefile` and then run:

```
$ make build
```
