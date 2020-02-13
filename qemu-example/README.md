# QEMU example

This is an example of running NuttX on QEMU.

## Usage

The Docker image downloads NuttX 8.2 and setup it for lm3s6965-ek:nsh configuration, adding some modifications to allow run it in QEMU using lm3s6965evb.

It can be build with `docker build -t nuttx docker` from repo root.

Also, an `expect` script has been added to show how use it in an automated way.

## Notes

The default config was modified:

 * `CONFIG_ARMV7M_TOOLCHAIN_BUILDROOT` is not set
 * `CONFIG_ARMV7M_OABI_TOOLCHAIN` is not set, and instead `CONFIG_ARMV7M_TOOLCHAIN_GNU_EABIL=y` is used.
 * `CONFIG_NSH_NETINIT=y` is used to avoid NSH wait for network initialization

