{
  description = "ThinkRail browser launcher and development environment";
  inputs.nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      bun = pkgs.callPackage ./nix/bun.nix { };
      thinkrail = pkgs.callPackage ./nix/package.nix { inherit bun; };
    in {
      packages.${system} = { inherit thinkrail; default = thinkrail; };
      apps.${system}.default = {
        type = "app";
        program = "${thinkrail}/bin/thinkrail";
      };
      devShells.${system}.default = pkgs.mkShell {
        packages = [ bun pkgs.nodejs_24 pkgs.git pkgs.ripgrep pkgs.pkg-config pkgs.stdenv.cc ];
        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        buildInputs = [ pkgs.stdenv.cc.cc.lib ];
        shellHook = ''
          thinkrail-nix-setup() {
            bun install --frozen-lockfile --ignore-scripts --linker=hoisted &&
            patchShebangs node_modules &&
            autoPatchelf node_modules/@rolldown/binding-linux-x64-gnu \
              node_modules/@tailwindcss/oxide-linux-x64-gnu \
              node_modules/lightningcss-linux-x64-gnu \
              node_modules/@esbuild/linux-x64/bin \
              node_modules/@turbo/linux-64/bin \
              node_modules/bun-pty/rust-pty/target/release/librust_pty.so
          }
        '';
        TURBO_TELEMETRY_DISABLED = "1";
        DO_NOT_TRACK = "1";
        ASTRO_TELEMETRY_DISABLED = "1";
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ];
      };
      checks.${system}.artifact = pkgs.runCommand "thinkrail-artifact-smoke" {
        nativeBuildInputs = [ bun pkgs.nodejs_24 pkgs.git pkgs.ripgrep pkgs.bash pkgs.coreutils ];
      } ''
        export HOME="$TMPDIR/home"
        export CI=1
        export SHELL=${pkgs.runtimeShell}
        mkdir -p "$HOME"
        cp -R ${thinkrail.src} source
        chmod -R u+w source
        cd source
        tar -xf ${thinkrail.dependencies}
        substituteInPlace packages/artifact-tests/src/artifactProbes.ts \
          --replace-fail '#!/bin/sh' '#!${pkgs.runtimeShell}'
        bun packages/artifact-tests/smoke-binary.ts ${thinkrail}/bin/thinkrail
        touch "$out"
      '';
      formatter.${system} = pkgs.nixfmt;
    };
}
