# Claude Code for all Linux machines (Fedora host and the NixOS VMs).
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
