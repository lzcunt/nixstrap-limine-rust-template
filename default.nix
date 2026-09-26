{
  buildPackages,
  craneLib,
  lib,
  stdenv,
  release ? false,
}:
let
  jsonFilter = path: _type: lib.hasSuffix ".json" path;
  ldFilter = path: _type: lib.hasSuffix ".ld" path;
  sourceFilter =
    path: type:
    (jsonFilter path type) || (ldFilter path type) || (craneLib.filterCargoSources path type);
  src = lib.cleanSourceWith {
    src = ./.;
    filter = sourceFilter;
    name = "source";
  };
  jsonSrc = lib.cleanSourceWith {
    src = ./.;
    filter = path: type: (jsonFilter path type) || (type == "directory");
  };
  ldSrc = lib.cleanSourceWith {
    src = ./.;
    filter = path: type: (ldFilter path type) || (type == "directory");
    name = "source";
  };
  dummySrc = craneLib.mkDummySrc {
    inherit src;
    # We need the targets dir and the linker scripts to be able to build the
    # deps only derivation, even if this is just a dummy src.
    extraDummyScript = ''
      cp -r ${jsonSrc}/kernel/targets $out/kernel/
      cp -r ${ldSrc}/kernel/src/arch $out/kernel/src
    '';
  };
  target =
    {
      x86_64 = "x86_64";
      aarch64 = "aarch64";
      riscv64 = "riscv64gc";
      loongarch64 = "loongarch64";
    }
    .${stdenv.hostPlatform.parsed.cpu.name};
in
{
  kernel = craneLib.buildPackage {
    inherit
      (craneLib.crateNameFromCargoToml {
        cargoToml = ./kernel/Cargo.toml;
      })
      pname
      version
      ;
    inherit src;
    inherit dummySrc;

    strictDeps = true;

    # I couldn't figure out how to run cargo in the kernel directory, so let's
    # just move its config here.
    postPatch = ''
      mv kernel/.cargo ./
    '';

    cargoVendorDir = craneLib.vendorMultipleCargoDeps {
      inherit (craneLib.findCargoFiles ./kernel) cargoConfigs;
      cargoLockList = [
        ./Cargo.lock

        # Unfortunately this approach requires IFD (import-from-derivation)
        # otherwise Nix will refuse to read the Cargo.lock from our toolchain
        # (unless we build with `--impure`).
        #
        # Another way around this is to manually copy the rustlib `Cargo.lock`
        # to the repo and import it with `./path/to/rustlib/Cargo.lock` which
        # will avoid IFD entirely but will require manually keeping the file
        # up to date!
        "${buildPackages.rustToolchain.passthru.availableComponents.rust-src}/lib/rustlib/src/rust/library/Cargo.lock"
      ];
    };

    cargoExtraArgs = "-p kernel --locked --target kernel/targets/${target}-kernel.json";
    CARGO_PROFILE = if release then "release" else "dev";

    doCheck = false;
    dontPatchELF = true;
  };
}
