{
  description = "Template for a Limine-compliant kernel in Rust using nixstrap.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixstrap = {
      url = "github:lzcunt/nixstrap";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
  };

  outputs =
    {
      self,
      crane,
      nixpkgs,
      nixstrap,
      rust-overlay,
    }:
    let
      lib = nixpkgs.lib;
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachSupportedSystem =
        f:
        lib.genAttrs supportedSystems (
          system:
          f {
            hostPkgs = import nixpkgs {
              inherit system;
              overlays = [
                rust-overlay.overlays.default
                self.overlays.default
              ];
            };
          }
        );
      mkConfiguration =
        hostPkgs: cross: module:
        nixstrap.lib.nixstrapConfiguration {
          inherit hostPkgs;
          modules = [
            (
              { pkgs, ... }:
              {
                nixpkgs.crossSystem.config = cross;
                nixpkgs.crossSystem.libc = null;

                nixpkgs.overlays = [
                  rust-overlay.overlays.default
                  self.overlays.default
                ];

                _module.args.craneLib = (crane.mkLib hostPkgs).overrideToolchain (p: p.rustToolchain);
              }
            )
            module
            ./bootstrap.nix
          ];
        };
    in
    {
      overlays.default = final: prev: {
        rustToolchain =
          let
            rust = prev.rust-bin;
          in
          if builtins.pathExists ./rust-toolchain.toml then
            rust.fromRustupToolchainFile ./rust-toolchain.toml
          else if builtins.pathExists ./rust-toolchain then
            rust.fromRustupToolchainFile ./rust-toolchain
          else
            rust.stable.latest.default.override {
              extensions = [
                "rust-src"
                "rustfmt"
              ];
            };
      };

      devShells = forEachSupportedSystem (
        { hostPkgs }:
        {
          default = hostPkgs.mkShell {
            packages = with hostPkgs; [
              rustToolchain
              openssl
              pkg-config
              cargo-deny
              cargo-edit
              cargo-watch
            ];

            env = {
              # Required by rust-analyzer
              RUST_SRC_PATH = "${hostPkgs.rustToolchain}/lib/rustlib/src/rust/library";
            };
          };
        }
      );

      nixstrapConfigurations = forEachSupportedSystem (
        { hostPkgs }:
        {
          x86_64 = mkConfiguration hostPkgs "x86_64-elf" {};
          aarch64 = mkConfiguration hostPkgs "aarch64-elf" {};
          riscv64 = mkConfiguration hostPkgs "riscv64-elf" {};
          loongarch64 = mkConfiguration hostPkgs "loongarch64-elf" {
            nixpkgs.config.allowUnsupportedSystem = true;
          };
        }
      );
    };
}
