# clanker-boxes-base: the shared NixOS guest for sandboxed coding-agent VMs.
# Built into an Incus VM image by `just clanker-image` and run on JsFlowdora.
# Per-VM (robot-named) configs will import this file and add project packages.
#
# This repo is public and the Nix store is readable by every user of a machine,
# so nothing secret may be referenced here. Tokens are pushed into a running VM
# from the host (`incus file push`), never built into the image.
{
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    # Disk image, boot loader, DHCP networking and the Incus guest agent.
    "${modulesPath}/virtualisation/incus-virtual-machine.nix"
  ];

  networking.hostName = lib.mkDefault "clanker-box";
  system.stateVersion = "26.11"; # NixOS release this guest was first built from; don't bump.

  nixpkgs.config.allowUnfree = true; # claude-code is unfree
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # The agents run as this user. It has no password and no sudo; the host
  # administers the VM as root through `incus exec`, so there is no SSH server.
  users.mutableUsers = false;
  users.users.clanker = {
    isNormalUser = true;
    uid = 1000;
  };

  environment.systemPackages = with pkgs; [
    git
    gh
    nodejs_24 # also what the T3 Code server needs
    codex
    # Same signed-manifest pin as home/modules/claude-code.
    (claude-code.override {
      manifest = lib.importJSON ../../../home/modules/claude-code/manifest.json;
    })
  ];

  # The Incus image module turns sshd on; the host uses `incus exec` instead.
  services.openssh.enable = lib.mkForce false;
  networking.firewall.enable = true; # no inbound ports open
}
