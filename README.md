
---

# Unofficial ECE391 Nix Flake

> ⚠️ **Disclaimer**
> This is an **unofficial** work-from-home setup. You are fully responsible for debugging any issues that arise.

This repository uses **Nix flakes** to provide a fully deterministic ECE391 development environment.
The goal: reproduce the EWS toolchain locally with a **single command**.

---

## Usage

Ensure you have **Nix with flakes enabled**, then run:

```bash
nix develop github:roshanah/riscv-qemu-toolchain
```

You’ll be dropped into a shell with the full RISC-V + QEMU toolchain available.

---

## Toolchain Compatibility

This flake is pinned to the **ECE391 Spring 2026** toolchain requirements.

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
* ❌ ARM / Apple Silicon (not tested, expect breakage)

---

## Notes

* If ECE updates the toolchain, this flake may become outdated.
* PRs to update version pins are welcome.
* If something breaks: it’s Nix, not ECE. Debug accordingly.

---
