# Cross compilation environment for `rust` targeting
[musl](https://www.musl-libc.org/) inspired by
[rust-embedded/cross](https://github.com/rust-embedded/cross)

Based on the official [Debian
stretch](https://github.com/sensorfu/rust-musl-arm.git) image and
[musl-cross-make](https://github.com/richfelker/musl-cross-make) tool to build a
rust cross-compilation development environment.

## Prebuilt images

| Rust toolchain | Cross Compiled Target Tag      |
| -------------- | ------------------------------ |
| stable         | arm-unknown-linux-musleabihf   |
| stable         | armv7-unknown-linux-musleabihf |
| stable         | x86_64-unknown-linux-musl      |

## Prebuilt libraries

- `musl-libc`
- `zlib`
- OpenSSL

## Usage

1. Pull the docker image from docker hub with target tag, e.g.
   `arm-unknown-linux-musleabihf`

```sh
$ docker pull skyuplam/rust-musl-armha:<target tag>
```

1. Cross compile target tag, e.g. `arm-unknown-linux-musleabihf` using the
   docker image

```sh
$ docker run --rm \
  --volume <path to your rust project>:/home/cross/project \
  --volume <path to your local cargo registry, e.g. ~/.cargo/registry>:/home/cross/.cargo/registry \ # optional, advoid cargo to update on every build
  skyuplam/rust-musl-armhf:<target tag> \
  <cargo command> # e.g. `cargo build --release`

# e.g. to run cargo build --release in the current directory
# with target x86_64-unknown-linux-musl
$ docker run --rm \
  --volume $(pwd):/home/cross/project \
  --volume ~/.cargo/registry:/home/cross/.cargo/registry \
  skyuplam/rust-musl-armhf:x86_64-unknown-linux-musl \
  cargo build --release
```

## Build your own docker image

```sh
# clone the project
$ git clone --recurse-submodules -j8 git@github.com:skyuplam/rust-musl-armhf.git

# change to the directory
$ cd rust-musl-armhf

# update submodules
$ git submodule update --remote --recursive
```

Change the variables in the `Makefile` and prepare your own `$TARGET-config.mak`
file and then run:

Here is a reference for SSL Arch which you can use to set `SSL_ARCH` to match
`TARGET`:

```
BS2000-OSD BSD-generic32 BSD-generic64 BSD-ia64 BSD-sparc64 BSD-sparcv8
BSD-x86 BSD-x86-elf BSD-x86_64 Cygwin Cygwin-i386 Cygwin-i486 Cygwin-i586
Cygwin-i686 Cygwin-x86 Cygwin-x86_64 DJGPP MPE/iX-gcc UEFI UWIN VC-CE VC-WIN32
VC-WIN32-ARM VC-WIN32-ONECORE VC-WIN64-ARM VC-WIN64A VC-WIN64A-ONECORE
VC-WIN64A-masm VC-WIN64I aix-cc aix-gcc aix64-cc aix64-gcc android-arm
android-arm64 android-armeabi android-mips android-mips64 android-x86
android-x86_64 android64 android64-aarch64 android64-mips64 android64-x86_64
bsdi-elf-gcc cc darwin-i386-cc darwin-ppc-cc darwin64-ppc-cc
darwin64-x86_64-cc dist gcc haiku-x86 haiku-x86_64 hpux-ia64-cc hpux-ia64-gcc
hpux-parisc-cc hpux-parisc-gcc hpux-parisc1_1-cc hpux-parisc1_1-gcc
hpux64-ia64-cc hpux64-ia64-gcc hpux64-parisc2-cc hpux64-parisc2-gcc hurd-x86
ios-cross ios-xcrun ios64-cross ios64-xcrun iossimulator-xcrun iphoneos-cross
irix-mips3-cc irix-mips3-gcc irix64-mips4-cc irix64-mips4-gcc linux-aarch64
linux-alpha-gcc linux-aout linux-arm64ilp32 linux-armv4 linux-c64xplus
linux-elf linux-generic32 linux-generic64 linux-ia64 linux-mips32 linux-mips64
linux-ppc linux-ppc64 linux-ppc64le linux-sparcv8 linux-sparcv9 linux-x32
linux-x86 linux-x86-clang linux-x86_64 linux-x86_64-clang linux32-s390x
linux64-mips64 linux64-s390x linux64-sparcv9 mingw mingw64 nextstep
nextstep3.3 sco5-cc sco5-gcc solaris-sparcv7-cc solaris-sparcv7-gcc
solaris-sparcv8-cc solaris-sparcv8-gcc solaris-sparcv9-cc solaris-sparcv9-gcc
solaris-x86-gcc solaris64-sparcv9-cc solaris64-sparcv9-gcc solaris64-x86_64-cc
solaris64-x86_64-gcc tru64-alpha-cc tru64-alpha-gcc uClinux-dist
uClinux-dist64 unixware-2.0 unixware-2.1 unixware-7 unixware-7-gcc vms-alpha
vms-alpha-p32 vms-alpha-p64 vms-ia64 vms-ia64-p32 vms-ia64-p64 vos-gcc
vxworks-mips vxworks-ppc405 vxworks-ppc60x vxworks-ppc750 vxworks-ppc750-debug
vxworks-ppc860 vxworks-ppcgen vxworks-simlinux
```

Example:

```sh
# e.g. to build x86_64-unknown-linux-musl # with x86_64-unknown-linux-musl-config.mak
$ make TARGET=x86_64-unknown-linux-musl SSL_ARCH=SSL_ARCH=linux-x86_64 build
```

## Supported `TARGET`s

Althought the primary purpose of the repo is based on arm[hf] and musl, all
`musl` target is also possible in theory.

You can get all `musl` target from `rustup` command as the following:

```sh
$ rustup target list | grep musl

aarch64-unknown-linux-musl
arm-unknown-linux-musleabi
arm-unknown-linux-musleabihf
armv5te-unknown-linux-musleabi
armv7-unknown-linux-musleabi
armv7-unknown-linux-musleabihf
i586-unknown-linux-musl
i686-unknown-linux-musl
mips-unknown-linux-musl
mips64-unknown-linux-muslabi64
mips64el-unknown-linux-muslabi64
mipsel-unknown-linux-musl
x86_64-unknown-linux-musl
```

See also [`musl-cross-make` repo](https://github.com/richfelker/musl-cross-make#supported-targets).

## Working with OpenSSL

Use [`openssl-probe`](https://crates.io/crates/openssl-probe) to find SSL
certificate locations on the system for OpenSSL.

1. Add `openssl-probe` to your `Cargo.toml` file.

```toml
# Cargo.toml
[dependencies]
openssl-probe = "0.1.2"
```

1. Add the following snippet to your main as the following:

```rust
extern crate openssl_probe;

fn main() {
    openssl_probe::init_ssl_cert_env_vars();
    //... your code
}
```
