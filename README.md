# Cross compilation environment for `rust` targeting [musl](https://www.musl-libc.org/) on ARMHF inspired by [rust-embedded/cross](https://github.com/rust-embedded/cross)

Based on the official [Debian stretch](https://github.com/sensorfu/rust-musl-arm.git) image and
[musl-cross-make](https://github.com/richfelker/musl-cross-make) tool to build a
rust cross-compilation development environment.

# Prebuilt images

| Rust toolchain | Cross Compiled Target Tag           |
|----------------|-------------------------------------|
| stable         | arm-unknown-linux-musleabihf        |
| stable         | armv7-unknown-linux-musleabihf      |


# Prebuilt libraries

+ `musl-libc`
+ `zlib`
+ OpenSSL

# Usage

1. Pull the docker image from docker hub with target tag, e.g. `arm-unknown-linux-musleabihf`

```
$ docker pull skyuplam/rust-musl-armha:<target tag>
```

2. Cross compile target tag, e.g. `arm-unknown-linux-musleabihf` using the docker image

```
$ docker run --rm \
  --volume <path to your rust project>:/home/cross/project \
  --volume <path to your local cargo registry, e.g. ~/.cargo/registry>:/home/cross/.cargo/registry \ # optional, advoid cargo to update on every build
  skyuplam/rust-musl-armhf:<target tag> \
  <cargo command> # e.g. `cargo build --release`
```

# Build your own docker image

Change the variables in the `Makefile` and then run:

```
# to build armv7-unknown-linux-musleabihf
$ make TARGET=arm7-unknown-linux-musleabihf build
```

# Supported `TARGET`s

Althought the primary purpose of the repo is based on arm[hf] and musl, all
`musl` target is also possible in theory.

You can get all `musl` target from `rustup` command as the following:

```bash
rustup target list | grep musl
```

See also [`musl-cross-make` repo](https://github.com/richfelker/musl-cross-make#supported-targets).

# Working with OpenSSL

Use [`openssl-probe`](https://crates.io/crates/openssl-probe) to find SSL
certificate locations on the system for OpenSSL.

1. Add `openssl-probe` to your `Cargo.toml` file.

```toml
# Cargo.toml
[dependencies]
openssl-probe = "0.1.2"
```

2. Add the following snipet to your main as the following:

```rust
extern crate openssl_probe;

fn main() {
    openssl_probe::init_ssl_cert_env_vars();
    //... your code
}
```
