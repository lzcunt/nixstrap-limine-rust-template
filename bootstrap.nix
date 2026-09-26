{
  craneLib,
  pkgs,
  ...
}:
let
  # The system package. This package provides the kernel and other components
  # of the system, all sharing a Cargo.lock file and a Cargo workspace.
  # You don't have to do this with your project, you can also package all the
  # components of your system separately, as showcased in the C template.
  system = pkgs.callPackage ./. { inherit craneLib; };
in
{
  # Timeout in seconds that Limine will use before automatically booting.
  boot.loader.timeout = 3;
  boot.loader.limine.enable = true;
  boot.entry."Limine Template" = {
    # We use the Limine boot protocol.
    protocol = "limine";
    # Path to the kernel to boot. boot():/ represents the partition on which
    # limine.conf is located.
    kernelPath = "boot():/boot/kernel";
  };

  # This copies the kernel from the system build, and places it in the ISO
  # image.
  isoImage.file."boot/kernel".source = "${system.kernel}/bin/kernel";
}
