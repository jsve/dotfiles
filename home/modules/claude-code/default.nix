# Claude Code for Linux, as a home-manager module (imported from linux-common.nix).
# A NixOS VM that uses home-manager can import this file directly; it needs unfree
# packages allowed. Without home-manager, put the same override in its system packages.
#
# Uses the nixpkgs packaging (wrapper, runtime dependencies) but takes the version
# and checksums from ./manifest.json, which is Anthropic's own release manifest.
# `just update-claude` downloads a new manifest and verifies its signature against
# ./release-key.asc before writing it, so Claude Code can be updated on its own
# without `just update` moving every other package.
{ pkgs, lib, ... }:
{
  home.packages = [
    (pkgs.claude-code.override { manifest = lib.importJSON ./manifest.json; })
  ];
}
