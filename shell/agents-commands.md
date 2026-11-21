# Agent context

## Commands

Run every project command through `just`, which runs it in this repository's dev image; the host carries no project toolchain.

In a fresh checkout: `just build`, then `just setup`. `just --list` shows the recipes.
