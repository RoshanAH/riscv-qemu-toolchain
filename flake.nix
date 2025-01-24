{
  description = "dev env for ece391";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # https://github.com/NixOS/nixpkgs/blob/81dcfeef771d77f0bc5cd8bfe01def33e7839fa9/pkgs/applications/virtualization/qemu/default.nix
    nixpkgs-qemu.url = "github:nixos/nixpkgs/5629520edecb69630a3f4d17d3d33fc96c13f6fe";
  };

  outputs = { self, nixpkgs, nixpkgs-qemu }: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      qemu-pkgs = nixpkgs-qemu.legacyPackages.${system};
      # pkgs-riscv = import nixpkgs {
      #   inherit system;
      #   crossSystem = {  
      #     system = "riscv64-none-elf";
      #   };
      # };

    in {
      packages.${system} = {
          qemu = (qemu-pkgs.qemu.override(oldAttrs: {
            hostCpuTargets = 
              (oldAttrs.hostCpuTargets or []) ++ ["riscv32-softmmu" "riscv64-softmmu"];
          })).overrideAttrs (oldAttrs: {
              patches = oldAttrs.patches ++ [ ./qemu.patch ];
              dontStrip = true;
              stripDebug = false;
              configureFlags = oldAttrs.configureFlags ++ [
                "--disable-werror"
                "--enable-debug"
                "--enable-debug-info"
                "--enable-system"
              ];
            });
        riscv-gnu-toolchain = pkgs.callPackage ./riscv-gnu-toolchain.nix {};
      };

      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = [ 
          self.packages.${system}.qemu 
          self.packages.${system}.riscv-gnu-toolchain
        ];
      };

  };
}
