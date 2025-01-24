{ fetchFromGitHub, fetchgit, stdenv, curl, texinfo, bison, flex, gmp, mpfr, libmpc, python3, perl, flock, expat }:
let
  # nix run -- nixpkgs#nix-prefetch-git --url https://sourceware.org/git/binutils-gdb.git --rev 060bfd90813b829e7c6a8f7347d5f834d406c29b
  binutilsSrc = fetchgit {
    url = "https://sourceware.org/git/binutils-gdb.git";
    rev = "060bfd90813b829e7c6a8f7347d5f834d406c29b"; #v2.40
    hash = "sha256-qUDQRvmQ80lBHxU/0TPy/c8oDEuayKWpisYqbHRYoWI=";
  };
  # nix run -- nixpkgs#nix-prefetch-git --url https://gcc.gnu.org/git/gcc.git --rev 091e10203846812c4e98b465ddfb36d12f146be8
  gccSrc = fetchgit {
    url = "https://gcc.gnu.org/git/gcc.git";
    rev = "091e10203846812c4e98b465ddfb36d12f146be8"; # 13
    hash = "sha256-3EkTO6wnsqzq6sqbv/uBXrgKtdtLS85805Vg2lsb08M=";
  };
  # nix run -- nixpkgs#nix-prefetch-git --url https://sourceware.org/git/glibc.git --rev 36f2487f13e3540be9ee0fb51876b1da72176d3f
  glibcSrc = fetchgit {
    url = "https://sourceware.org/git/glibc.git";
    rev = "36f2487f13e3540be9ee0fb51876b1da72176d3f"; # 2.38
    hash = "sha256-o/lKFroKT9OmQunHi84Zklb48LNJAzp7XVXeMc8FEGg=";
  };
  # nix run -- nixpkgs#nix-prefetch-git --url https://sourceware.org/git/binutils-gdb.git --rev 71c90666e601c511a5f495827ca9ba545e4cb463
  gdbSrc = fetchgit {
    url = "https://sourceware.org/git/binutils-gdb.git";
    rev = "71c90666e601c511a5f495827ca9ba545e4cb463"; # 13
    hash = "sha256-mc6HmuOJud3ycTcDqkRQP/AuXZhc/VQ4q119MhLq478=";
  };
  newlibSrc = fetchgit {
    url = "https://sourceware.org/git/newlib-cygwin.git";
    rev = "bf94b87f54de862a1c2482d411a18973b29264fe"; 
    hash = "sha256-tSYZfc8AM3fg6BhJYM8LqfWU5s0kpmRLHFZJtokpJXc=";
  };
in
stdenv.mkDerivation rec {
  pname = "riscv-gnu-toolchain";
  version = "2024.12.16";
  srcs =
    (fetchFromGitHub {
      owner = "riscv-collab";
      repo = pname;
      rev = version;
      sha256 = "sha256-FZE7DIW+aP5mAmmWdgMXohOhMLngQrG2zoyF+zV97+A=";
    });

  postUnpack = ''
    copy() {
      cp -pr --reflink=auto -- "$1" "$2"
    }

    rm -r $sourceRoot/{binutils,gcc,glibc,gdb,newlib}

    copy ${binutilsSrc} $sourceRoot/binutils
    copy ${gccSrc} $sourceRoot/gcc
    copy ${glibcSrc} $sourceRoot/glibc
    copy ${gdbSrc} $sourceRoot/gdb
    copy ${newlibSrc} $sourceRoot/newlib

    chmod -R u+w -- "$sourceRoot"
  '';

  nativeBuildInputs = [
    curl
    perl
    python3
    texinfo
    bison
    flex
    gmp
    mpfr
    libmpc

    flock # required for installing file
    expat # glibc
  ];

  enableParallelBuilding = true;

  configureFlags = [
      "--enable-multilib"
  ];

  postConfigure = ''
    # nixpkgs will set those value to bare string "ar", "objdump"...
    # however we are cross-compiling, we must let $CC to determine which bintools to use.
    unset AR AS LD OBJCOPY OBJDUMP
  '';

  # RUN: make
  makeFlags =
    [
      # Don't auto update source
      "GCC_SRC_GIT="
      "BINUTILS_SRC_GIT="
      "GLIBC_SRC_GIT="
      "GDB_SRC_GIT="
      "NEWLIB_SRC_GIT="

      # Install to nix out dir
      "INSTALL_DIR=${placeholder "out"}"
    ];

  # -Wno-format-security
  hardeningDisable = [ "format" ];

  dontPatchELF = true;
  dontStrip = true;
}
