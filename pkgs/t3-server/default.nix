# The headless T3 Code server (`t3`), taken from upstream's prebuilt release tarball
# instead of the nixpkgs `t3code` package: that one builds the Electron desktop app
# from source and lags behind upstream releases.
#
# The version and checksums live in ./release.json; `just update-t3` rewrites it
# from the release's SHA256SUMS file.
#
# The tarball is installed untouched. Its `t3` binary is a Node single-executable
# with the application appended to it, which stripping or patching can corrupt, so
# it needs a machine that can run ordinary Linux binaries: on NixOS that means
# `programs.nix-ld.enable = true` (see hosts/vms/clanker-boxes/base.nix).
{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  release = lib.importJSON ./release.json;
  system = stdenvNoCC.hostPlatform.system;
  arch =
    {
      x86_64-linux = "x64";
      aarch64-linux = "arm64";
    }
    .${system} or (throw "t3-server: no upstream release for ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "t3-server";
  inherit (release) version;

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${release.version}/t3-${release.version}-linux-${arch}.tar.gz";
    sha256 = release.sha256.${system};
  };

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true; # no stripping, no patchelf, no shebang rewriting

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec/t3-server" "$out/bin"
    cp -R . "$out/libexec/t3-server"
    # A wrapper, not a symlink, so the server finds client/ and node_modules/ next to
    # the real binary whichever way it resolves its own path.
    printf '#!/bin/sh\nexec %s "$@"\n' "$out/libexec/t3-server/t3" > "$out/bin/t3"
    chmod +x "$out/bin/t3"
    runHook postInstall
  '';

  meta = {
    description = "Headless T3 Code server, from upstream's prebuilt release";
    homepage = "https://t3.codes";
    changelog = "https://github.com/pingdotgg/t3code/releases/tag/v${release.version}";
    license = lib.licenses.mit;
    mainProgram = "t3";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
