{ bun, fetchurl }:
bun.overrideAttrs (_: {
  version = "1.4.3";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v1.4.3/bun-linux-x64-baseline.zip";
    sha256 = "1fc2edac843102909e3a1be1d8d9802cc6071cf074e67e88231f4ffe0f8b397b";
  };
})
