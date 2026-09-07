{
  lib,
  fetchFromGitHub,
  fetchgit,
  stdenv,
  curl,
  texinfo,
  bison,
  flex,
  gmp,
  mpfr,
  libmpc,
  python3,
  perl,
  flock,
  expat,
  ncurses,
  zlib,
}:
let
  # nix run -- nixpkgs#nix-prefetch-git --url git://sourceware.org/git/binutils-gdb.git
  binutilsSrc = fetchgit {
    url = "git://sourceware.org/git/binutils-gdb.git";
    rev = "c7f28aad0c99d1d2fec4e52ebfa3735d90ceb8e9";
    hash = "sha256-uCeNk6eIk1G2YyohCZEF04buMzu7boPt3k2nQbdkxqU=";
  };
  # nix run -- nixpkgs#nix-prefetch-git --url git://gcc.gnu.org/git/gcc.git
  gccSrc = fetchgit {
    url = "git://gcc.gnu.org/git/gcc.git";
    rev = "c891d8dc23e1a46ad9f3e757d09e57b500d40044";
    hash = "sha256-AAu/jE3MlMgvd+xagn9ujJ8PpKJZ16iZXhU9QxNRZSk=";
  };
  # nix run -- nixpkgs#nix-prefetch-git --url git://sourceware.org/git/glibc.git
  glibcSrc = fetchgit {
    url = "git://sourceware.org/git/glibc.git";
    rev = "ef321e23c20eebc6d6fb4044425c00e6df27b05f";
    hash = "sha256-wFaBz6nRRW/uzri8ra/sYTNHpHpPO3o7uH3uXM6kIH8=";
  };
  # nix run -- nixpkgs#nix-prefetch-git --url git://sourceware.org/git/binutils-gdb.git
  gdbSrc = fetchgit {
    url = "git://sourceware.org/git/binutils-gdb.git";
    rev = "6bda1c19bcd16eff8488facb8a67d52a436f70e7";
    hash = "sha256-ghCWNqiYyp8NdNlMfYG5opZgU+PzYk/PiF8HT/aPr2o=";
  };
  # nix run -- nixpkgs#nix-prefetch-git --url git://sourceware.org/git/newlib-cygwin.git
  newlibSrc = fetchgit {
    url = "git://sourceware.org/git/newlib-cygwin.git";
    rev = "26f7004bf73c421c3fd5e5a6ccf470d05337b435";
    hash = "sha256-6jaggRYn2WH/aWCQsxzC15y5aYyBPBDkqN7C16u63ac=";
  };
in
stdenv.mkDerivation rec {
  pname = "riscv-gnu-toolchain";
  version = "2024.04.12";
  src = fetchFromGitHub {
    owner = "riscv-collab";
    repo = pname;
    rev = version;
    # linux-headers/ ships case-colliding filenames (xt_MARK.h vs xt_mark.h, and
    # 7 more). On a case-insensitive filesystem -- which the macOS /nix volume is
    # unless it was created case-sensitive -- 8 of them collapse during unpack, so
    # the fetched tree, and therefore its hash, differs from Linux and no single
    # pin can satisfy both platforms. Those headers are only a prerequisite of the
    # linux/musl stage1 targets; this flake builds the newlib bare-metal toolchain,
    # so dropping them makes the tree byte-identical everywhere.
    postFetch = "rm -rf $out/linux-headers";
    hash = "sha256-TGsaVJiPLf8K94JUCaxVH3dzKoeIkBx34mULKyRTdb4=";
  };

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

  # macOS only. GCC 13's gcc/system.h includes "safe-ctype.h", which poisons
  # toupper/tolower with object-like macros. Under libc++ (the macOS default)
  # <vector>/<map> reach <locale>, which declares those as members, so any
  # translation unit pulling a C++ header after system.h fails to compile.
  #
  # Hoisting system.h's own guarded includes is not enough: libcc1plugin.cc
  # includes <vector> directly, well after system.h. So the headers have to be
  # pulled in unconditionally, before the poisoning, for every TU.
  #
  # That unconditional include is exactly why this must stay Darwin-only. On
  # libstdc++ it regresses the build: dragging <string>/<map> in early changes
  # include-guard state so that <sstream>'s later <locale> is parsed after the
  # poisoning, breaking genrvv-type-indexer.cc. Linux keeps pristine upstream
  # behaviour, which is the configuration GCC supports.
  postPatch = lib.optionalString stdenv.hostPlatform.isDarwin ''
    printf '%s\n' \
      '#ifdef __cplusplus' \
      '# include <algorithm>' \
      '# include <array>' \
      '# include <functional>' \
      '# include <list>' \
      '# include <map>' \
      '# include <set>' \
      '# include <string>' \
      '# include <vector>' \
      '#endif' \
      '#include "safe-ctype.h"' \
      > gcc/gcc/cxx-headers-before-safe-ctype.h

    substituteInPlace gcc/gcc/system.h \
      --replace-fail '#include "safe-ctype.h"' \
                     '#include "cxx-headers-before-safe-ctype.h"'
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
    ncurses # gdb tui
  ];

  buildInputs = [
    # binutils/gdb/gcc bundle an ancient zlib whose zutil.h does
    # `#define fdopen(fd,mode) NULL` under TARGET_OS_MAC, which breaks against
    # the macOS SDK's <stdio.h>. Build against the system zlib instead.
    zlib
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
  makeFlags = [
    # Don't auto update source
    "GCC_SRC_GIT="
    "BINUTILS_SRC_GIT="
    "GLIBC_SRC_GIT="
    "GDB_SRC_GIT="
    "NEWLIB_SRC_GIT="

    # Install to nix out dir
    "INSTALL_DIR=${placeholder "out"}"
    "BINUTILS_TARGET_FLAGS_EXTRA=--with-system-zlib"
    "GCC_EXTRA_CONFIGURE_FLAGS=--with-system-zlib"
  ];

  # makeFlags entries are word-split, so a value holding several flags has to go
  # through makeFlagsArray.
  preBuild = ''
    makeFlagsArray+=("GDB_TARGET_FLAGS_EXTRA=--enable-tui --with-system-zlib")
  '';

  postInstall = ''
    for path in "$out/bin/"*; do
      base=$(basename "$path")
      case "$base" in
        *unknown-elf*)
          newbase=$(echo "$base" | sed 's/unknown-elf/illinix/')
          ln -s "$path" "$out/bin/$newbase"
          ;;
      esac
    done
  '';
  # -Wno-format-security
  hardeningDisable = [ "format" ];

  dontPatchELF = true;
  dontStrip = true;
}
