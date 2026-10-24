---
id: module-nix
type: module-design
status: active
title: Nix packaging
parent: architecture
depends-on: [module-cli]
---

## Responsibility

The root flake exposes the source-built browser launcher, a development shell, and
an artifact smoke check for x86_64-linux. It does not package the Electrobun desktop
installer. Adding another platform requires a platform-specific dependency hash and
native build/runtime validation.

## Build and runtime contract

- Bun matches `package.json` exactly, independently of the nixpkgs Bun version.
- A fixed-output derivation installs the frozen Bun lockfile with lifecycle scripts
  disabled. Its normalized tar archive preserves relative workspace links. Only
  manifests, patches, the lockfile, and the Bun version affect this fetch step.
- The application builds offline through the existing `build:binary` path. The
  frontend's native build tools are patched before execution. The installed
  executable and external `bun-pty` library are patched for the Nix store;
  `BUN_PTY_LIB` selects that library instead of the binary's embedded upstream copy.
- The wrapper adds runtime tools after the user's PATH and blocks installer-owned
  update/uninstall commands. Nix owns installation lifecycle; app state remains
  under the normal user paths. The shared source identity stays on the dev channel,
  so release update discovery is absent.
- `checks` runs the existing isolated CLI artifact probes against the installed
  package, including PTY IO and bundled extensions. No provider credentials are used.
  The wrapper permits update/uninstall help, but never their mutating forms.

## Validation

Nix build/check and manual NixOS launch are separate evidence. A successful Linux
source build alone does not establish NixOS runtime support. Record failures and
complete the manual checklist in `nix/README.md` before claiming tested support.
