# Nixstrap Limine Rust Template

This repository will demonstrate how to set up a basic Limine-compliant kernel
in Rust using nixstrap.

## How to use this?

### Dependencies

The only manually installed dependency is [nix](https://nixos.org/download/).
The rest of the dependencies will be built and installed by nix.

### Configurations

The template provides multiple configurations that build for different targets.
- `aarch64`
- `riscv64`
- `x86_64`

### Building

Use the following command to build any of the configurations:
```
$ nix build .#nixstrapConfigurations.<build-double>.<configuration>.config.system.build.isoImage
```

For example, to build a bootable ISO image for x86_64 on a x86_64-linux build
machine, use the following command:
```
$ nix build .#nixstrapConfigurations.x86_64-linux.x86_64.config.system.build.isoImage
```

To generate a QEMU runner for x86_64, use the following command:
```
# nix build .#nixstrapConfigurations.x86_64-linux.x86_64.config.system.build.qemuRunner
```
