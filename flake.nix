{
  description = "dev env for ece391";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      qemu = pkgs.qemu.override(oldAttrs: {
        hostCpuTargets = oldAttrs.hostCpuTargets ++ ["riscv32-softmmu" "riscv64-softmmu"];
      }).overrideAttrs (oldAttrs: {
        version = "9.0.2";
        patches = oldAttrs.patches ++ [ ]
      });
    in {
      packages.${system}.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; ([ # add these if necessary
          # libmpc
          # mpfr
          # gmp
          # bison
          # flex
          # texinfo
          # expat
          # libslirp
        ]) ++ [
          # qemu # add this when im ready
        ];
      };
  };
}
