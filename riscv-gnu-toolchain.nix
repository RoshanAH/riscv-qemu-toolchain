{ fetchFromGitHub, fetchgit, stdenv, curl, texinfo, bison, flex, gmp, mpfr, libmpc, python3, perl, flock, expat }:
let
  # nix run -- nixpkgs#nix-prefetch-git --url https://sourceware.org/git/binutils-gdb.git
  binutilsSrc = fetchgit {
    url = "https://sourceware.org/git/binutils-gdb.git";
    rev = "c7f28aad0c99d1d2fec4e52ebfa3735d90ceb8e9";
    hash = "sha256-uCeNk6eIk1G2YyohCZEF04buMzu7boPt3k2nQbdkxqU=";
  };
  # nix run -- nixpkgs#nix-prefetch-git --url https://gcc.gnu.org/git/gcc.git
  gccSrc = fetchgit {
    url = "https://gcc.gnu.org/git/gcc.git";
    rev = "c891d8dc23e1a46ad9f3e757d09e57b500d40044";
    hash = "sha256-AAu/jE3MlMgvd+xagn9ujJ8PpKJZ16iZXhU9QxNRZSk=";
  };
  # nix run -- nixpkgs#nix-prefetch-git --url https://sourceware.org/git/glibc.git
  glibcSrc = fetchgit {
    url = "https://sourceware.org/git/glibc.git";
    rev = "ef321e23c20eebc6d6fb4044425c00e6df27b05f";
    hash = "sha256-wFaBz6nRRW/uzri8ra/sYTNHpHpPO3o7uH3uXM6kIH8=";
  };
  # nix run -- nixpkgs#nix-prefetch-git --url https://sourceware.org/git/binutils-gdb.git 
  gdbSrc = fetchgit {
    url = "https://sourceware.org/git/binutils-gdb.git";
    rev = "6bda1c19bcd16eff8488facb8a67d52a436f70e7";
    hash = "sha256-ghCWNqiYyp8NdNlMfYG5opZgU+PzYk/PiF8HT/aPr2o=";
  };
  # nix run -- nixpkgs#nix-prefetch-git --url https://sourceware.org/git/newlib-cygwin.git 
  newlibSrc = fetchgit {
    url = "https://sourceware.org/git/newlib-cygwin.git";
    rev = "26f7004bf73c421c3fd5e5a6ccf470d05337b435"; 
    hash = "sha256-6jaggRYn2WH/aWCQsxzC15y5aYyBPBDkqN7C16u63ac=";
  };
in
stdenv.mkDerivation rec {
  pname = "riscv-gnu-toolchain";
  version = "2024.04.12";
  srcs =
    (fetchFromGitHub {
      owner = "riscv-collab";
      repo = pname;
      rev = version;
      sha256 = "sha256-MlsYeSJw3uCZg86uNvUdKwEpvhrU9TrnhMA0KkCOyn8=";
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
