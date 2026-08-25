
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

* ✅ **x86_64**

---

## Notes

* If ECE updates the toolchain, this flake may become outdated.

