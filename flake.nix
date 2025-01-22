{
  description = "dev env for ece391";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-qemu.url = "github:nixos/nixpkgs/5629520edecb69630a3f4d17d3d33fc96c13f6fe";
  };

  outputs = { self, nixpkgs, nixpkgs-qemu }: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      qemu-pkgs = nixpkgs-qemu.legacyPackages.${system};

      qemu = (qemu-pkgs.qemu.override(oldAttrs: {
        hostCpuTargets = 
          (oldAttrs.hostCpuTargets or []) ++ ["riscv32-softmmu" "riscv64-softmmu"];
      })).overrideAttrs (oldAttrs: {
        patches = oldAttrs.patches ++ [ ./qemu.patch ];
        # patchFlags = [ "-p0" ];
        dontStrip = true;
        stripDebug = false;
        configureFlags = oldAttrs.configureFlags ++ [
            "--enable-system"
            "--disable-werror"
            "--enable-debug"
            "--enable-debug-info"
        ];
      });

    in {

      packages.${system}.default = pkgs.mkShell {
        # nativeBuildInputs = with pkgs; ([ # add these if necessary
        #   # libmpc
        #   # mpfr
        #   # gmp
        #   # bison
        #   # flex
        #   # texinfo
        #   # expat
        #   # libslirp
        # ]) ++ [
        #   qemu # add this when im ready
        # ];
        nativeBuildInputs = [ qemu ];
      };

  };
}
