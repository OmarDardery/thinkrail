{ lib, stdenv, bun, nodejs_24, git, ripgrep, xdg-utils, autoPatchelfHook, makeWrapper, callPackage }:
let
  dependencies = callPackage ./dependencies.nix { inherit bun; };
  runtimePath = lib.makeBinPath [ bun nodejs_24 git ripgrep xdg-utils ];
in
stdenv.mkDerivation {
  pname = "thinkrail";
  version = "0.0.0-dev";
  src = lib.cleanSourceWith {
    src = ../.;
    filter = path: type:
      lib.cleanSourceFilter path type
      && !(builtins.elem (baseNameOf path) [ "node_modules" "dist" ".turbo" "result" ]);
  };
  nativeBuildInputs = [ bun nodejs_24 git autoPatchelfHook makeWrapper ];
  buildInputs = [ stdenv.cc.cc.lib ];
  TURBO_TELEMETRY_DISABLED = "1";
  DO_NOT_TRACK = "1";
  ASTRO_TELEMETRY_DISABLED = "1";
  dontConfigure = true;
  postUnpack = ''
    cd "$sourceRoot"
    tar -xf ${dependencies}
    chmod -R u+w node_modules
    cd ..
  '';
  preBuild = ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    patchShebangs node_modules
    autoPatchelf node_modules/@rolldown/binding-linux-x64-gnu \
      node_modules/@tailwindcss/oxide-linux-x64-gnu \
      node_modules/lightningcss-linux-x64-gnu \
      node_modules/@esbuild/linux-x64/bin \
      node_modules/@turbo/linux-64/bin
  '';
  buildPhase = ''
    runHook preBuild
    bun run build:binary
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    install -Dm755 apps/cli/dist/thinkrail "$out/libexec/thinkrail"
    install -Dm755 node_modules/bun-pty/rust-pty/target/release/librust_pty.so \
      "$out/lib/thinkrail/librust_pty.so"
    mkdir -p "$out/bin"
    makeWrapper "$out/libexec/thinkrail" "$out/bin/thinkrail" \
      --suffix PATH : ${runtimePath} \
      --set BUN_PTY_LIB "$out/lib/thinkrail/librust_pty.so" \
      --run 'case "''${1-}" in update|uninstall) case "''${2-}" in --help|-h) ;; *) echo "ThinkRail is managed by Nix; update or remove it through your Nix configuration or profile." >&2; exit 1 ;; esac ;; esac'
    runHook postInstall
  '';
  passthru = { inherit dependencies; };
  meta = {
    description = "ThinkRail agentic IDE with a browser interface";
    homepage = "https://github.com/JetBrains/thinkrail";
    license = lib.licenses.asl20;
    mainProgram = "thinkrail";
    platforms = [ "x86_64-linux" ];
  };
}
