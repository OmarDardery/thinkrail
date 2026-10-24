{ lib, stdenvNoCC, bun, cacert }:
stdenvNoCC.mkDerivation {
  pname = "thinkrail-node-modules";
  version = "1";
  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../package.json
      ../bun.lock
      ../patches
      (lib.fileset.fileFilter (file: file.name == "package.json") ../apps)
      (lib.fileset.fileFilter (file: file.name == "package.json") ../packages)
      (lib.fileset.fileFilter (file: file.name == "package.json") ../pi-extensions)
      (lib.fileset.fileFilter (file: file.name == "package.json") ../thinkrail-extensions)
    ];
  };
  nativeBuildInputs = [ bun ];
  SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  dontConfigure = true;
  dontFixup = true;
  buildPhase = ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    bun install --frozen-lockfile --ignore-scripts --linker=hoisted
  '';
  installPhase = ''
    find . -type d -name node_modules -prune -print0 \
      | LC_ALL=C sort -z \
      | tar --null --files-from=- --sort=name --mtime=@1 \
          --owner=0 --group=0 --numeric-owner --format=gnu --hard-dereference -cf "$out"
  '';
  outputHashAlgo = "sha256";
  outputHashMode = "flat";
  outputHash = "0af71a43a3ffda0baaa6f124be71a0988b4e3a0aacbf660ebcf0baf45952c4f9";
}
