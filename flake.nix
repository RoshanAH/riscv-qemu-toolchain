{
  description = "dev env for ece391";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # nixpkgs with the correct version of qemu so we don't have to package it ourselves
    # https://github.com/NixOS/nixpkgs/blob/81dcfeef771d77f0bc5cd8bfe01def33e7839fa9/pkgs/applications/virtualization/qemu/default.nix
    nixpkgs-qemu.url = "github:nixos/nixpkgs/5629520edecb69630a3f4d17d3d33fc96c13f6fe";
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem =
        { config
        , self'
        , inputs'
        , pkgs
        , system
        , ...
        }: {
          packages = {
            qemu = let 
              inherit (inputs'.nixpkgs-qemu.legacyPackages) qemu;
            in
              (qemu.override (oldAttrs: {
                hostCpuTargets =
                  (oldAttrs.hostCpuTargets or [ ]) ++ [ "riscv32-softmmu" "riscv64-softmmu" ];
              })).overrideAttrs (oldAttrs: {
                patches = oldAttrs.patches ++ [ ./qemu.patch ];
                dontStrip = true;
                stripDebug = false;
                configureFlags =
                  oldAttrs.configureFlags
                  ++ [
                    "--disable-werror"
                    "--enable-debug"
                    "--enable-debug-info"
                    "--enable-system"
                  ];
              });
            riscv-gnu-toolchain = pkgs.callPackage ./riscv-gnu-toolchain.nix { };
          };

          devShells.default = pkgs.mkShell {
            packages = [
              self'.packages.qemu
              self'.packages.riscv-gnu-toolchain
              pkgs.screen
              pkgs.bear
            ];
          };
        };
      flake = { };
    };
}
