# clanker-boxes-base: the shared NixOS guest for sandboxed coding-agent VMs.
# Built into an Incus VM image by `just flowdora clanker-image` and run on JsFlowdora.
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
  # The Incus image module gives root an empty password; lock it instead. Nobody can
  # log in with a password at all, hence allowNoPasswordLogin.
  users.users.root.hashedPassword = lib.mkForce "!";
  users.allowNoPasswordLogin = true;
  users.users.clanker = {
    isNormalUser = true;
    uid = 1000;
  };

  # The same core command-line tools as the other machines, plus what the agents need.
  environment.systemPackages =
    import ../../common/system-packages-list.nix { inherit pkgs; }
    ++ (with pkgs; [
      git
      gh
      nodejs_26
      codex
      # T3 Code: provides the headless server (`t3 serve`) that the desktop app pairs
      # with. It finds claude and codex on PATH and uses their own logins.
      t3code
      # Same signed-manifest pin as home/modules/claude-code.
      (claude-code.override {
        manifest = lib.importJSON ../../../home/modules/claude-code/manifest.json;
      })
    ]);

  # T3 Code sends usage telemetry by default; this is its documented opt-out.
  environment.variables.T3CODE_TELEMETRY_ENABLED = "false";

  # The only way in from outside: the VM joins the tailnet as its own tagged device.
  # It is not joined yet at first boot; that needs an auth key supplied at runtime.
  services.tailscale.enable = true;

  # The Incus image module turns sshd on; the host uses `incus exec` instead.
  services.openssh.enable = lib.mkForce false;
  networking.firewall.enable = true; # no inbound ports open
}
