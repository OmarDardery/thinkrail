# Nix / NixOS

The flake builds the browser-based ThinkRail CLI from source on **x86_64-linux**.
It includes the web UI and bundled extensions, pins Bun 1.4.3, and patches the
terminal's native library. The Electrobun desktop installer is not packaged.
This is fork-level support pending NixOS validation, not a nixpkgs submission or
an upstream endorsement.

## Run and verify

Enable `nix-command` and `flakes` in your Nix configuration, then:

```sh
nix run github:OmarDardery/thinkrail/feat/nix-support -- --no-open
```

Open the local URL printed by the launcher. Omit `--no-open` to let `xdg-open`
launch your browser. On the first build, Nix downloads dependencies; the actual
application build runs offline in the Nix sandbox.

Run these checks before reporting success:

```sh
nix build github:OmarDardery/thinkrail/feat/nix-support -L
./result/bin/thinkrail --version
nix flake check github:OmarDardery/thinkrail/feat/nix-support -L
```

The flake check runs the existing isolated artifact probes, including bundled
skills/extensions and real terminal IO. It uses disposable app/provider directories
and synthetic providers, without real provider credentials.

Manual NixOS checklist:

- Launch from a normal shell outside `nix develop`; the printed URL loads the UI.
- Add a disposable Git repository and create a workspace.
- Open a terminal; check input, output, resize, and closing/reopening.
- Check bundled skills/extensions, then authenticate a provider and send a prompt.
- Restart and confirm the project and settings persist.
- Check automatic browser opening both under Wayland and X11 if you use both.

Report the command, full error, architecture, and desktop session when a check
fails. Redact tokens and private project details.

## Install declaratively

Add the fork as a flake input:

```nix
inputs.thinkrail = {
  url = "github:OmarDardery/thinkrail/feat/nix-support";
};
```

Then add the package in a NixOS module (with `inputs` passed through `specialArgs`):

```nix
{ inputs, pkgs, ... }: {
  environment.systemPackages = [
    inputs.thinkrail.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

For Home Manager, use the same package in `home.packages` and pass `inputs` through
`extraSpecialArgs` if necessary. Existing provider credentials and app state keep
their normal locations. The wrapper preserves user tools ahead of its fallback
Bun, Node, Git, ripgrep, and browser opener.

Update/remove through your Nix configuration or profile. `thinkrail update` and
`thinkrail uninstall` are blocked for this package; their help remains available.
The build keeps the source/dev release identity, so it does not advertise a
published binary updater. App data is not removed by Nix uninstalling the package.

## Development

From a checkout:

```sh
nix develop
thinkrail-nix-setup
bun run dev
```

`thinkrail-nix-setup` installs frozen dependencies without lifecycle scripts, then
patches the frontend build tools and PTY library for NixOS. Run it again after
changing the lockfile. Desktop development and Playwright browser provisioning
are outside this shell's current scope.

## Dependency updates

`nix/dependencies.nix` fetches only manifests, patches, and the frozen lockfile.
Its deterministic tar hash was reproduced with clean and cached Bun installs.
When those inputs change, temporarily set `outputHash = lib.fakeHash`, run
`nix build .#thinkrail.dependencies -L` from a checkout, and replace the hash with
the `got:` value. Then run `nix build` and `nix flake check` without disabling the
sandbox. Keep the Bun version and checksum in `nix/bun.nix` aligned with the root
`packageManager` pin.

## Validation recorded for this change

- Linux x86_64, Bun 1.4.3: existing `build:binary` and `smoke:binary` passed.
- Nix evaluation/build/artifact check: pending; Nix is unavailable in the authoring
  environment. The pinned dependency hash still needs confirmation by Nix itself.
- Full no-agent browser suite: blocked before execution by a truncated Chromium
  download from Playwright's CDN.
- Interactive NixOS, real-provider, Wayland/X11, and desktop tests: pending.
