
---

# Unofficial ECE391 Nix Flake

> ⚠️ **Disclaimer**
> This is an **unofficial** work-from-home setup. You are fully responsible for debugging any issues that arise.

This repository uses **Nix flakes** to provide a fully deterministic ECE391 development environment.

---

## Usage

Ensure you have **Nix with flakes enabled**, then run:

```bash
nix develop "git+ssh://git@github.com/illinois-ece391/nix-toolchain"
```

You’ll be dropped into a shell with the full RISC-V + QEMU toolchain available.

---

## Toolchain Compatibility

This flake is pinned to the **ECE391 Fall 2026** toolchain requirements.

To verify compatibility with your current semester, run:

```bash
riscv64-unknown-elf-gcc --version
riscv64-unknown-elf-gdb --version
qemu-system-riscv64 --version
```

Compare the output against the versions installed on an EWS machine.

---

## Architecture Support

The flake evaluates for `x86_64-linux`, `aarch64-linux`, `x86_64-darwin` and
`aarch64-darwin`. Build status as actually tested:

| System | Status |
| --- | --- |
| `aarch64-darwin` | Built end to end and smoke-tested (gcc 13.2.0, gdb 14.1 + TUI, all 6 multilibs, cross-compiles to RISC-V ELF) |
| `x86_64-linux` | Built through binutils, gdb, gcc stage1 and newlib with no errors; the run was stopped before gcc stage2 finished, so the tail is unverified |
| `aarch64-linux`, `x86_64-darwin` | Evaluate, but never built |

On macOS the shell does not include a host `gdb` (nixpkgs marks it unsupported
there); use the toolchain's own `riscv64-unknown-elf-gdb`, which is what you
want for debugging RISC-V targets anyway.

---

## Notes

* If ECE updates the toolchain, this flake may become outdated.

