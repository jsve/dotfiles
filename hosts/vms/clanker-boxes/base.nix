# clanker-boxes-base: the shared NixOS guest for sandboxed coding-agent VMs.
# Built into an Incus VM image by `just flowdora clanker-image` and run on JsFlowdora.
# Per-VM (robot-named) configs in flake.nix build on this file and add their own packages.
# Every box rebuilds itself from the copy of this repo that the host publishes into it
# (see clanker-apply below), so the image only has to be good enough to boot and do that.
#
# This repo is public and the Nix store is readable by every user of a machine,
# so nothing secret may be referenced here. Tokens are pushed into a running VM
# from the host (`incus file push`), never built into the image.
{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
let
  # Where the Incus profile mounts the host's published folder, read-only.
  hostShare = "/mnt/host";
  # T3 Code's headless server, which the desktop app pairs with. Pinned in pkgs/t3-server.
  t3-server = pkgs.callPackage ../../../pkgs/t3-server { };
in
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
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true; # required for zsh to be a login shell

  # The clanker user gets the same shell setup and command-line tools as the other
  # machines (home/core.nix), so a terminal in a VM behaves like one anywhere else.
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.clanker = {
    imports = [ ../../../home/core.nix ];
    home.stateVersion = "26.11"; # release first used for this user; don't bump.
  };

  # The same core command-line tools as the other machines, plus what the agents need.
  environment.systemPackages =
    import ../../common/system-packages-list.nix { inherit pkgs; }
    ++ (with pkgs; [
      git
      codex
      t3-server
      # Same signed-manifest pin as home/modules/claude-code.
      (claude-code.override {
        manifest = lib.importJSON ../../../home/modules/claude-code/manifest.json;
      })
    ]);

  # Lets ordinary prebuilt Linux binaries run on NixOS. The T3 server needs it, and
  # so do the prebuilt tools that agents install through npm, pip and the like.
  programs.nix-ld.enable = true;

  # T3 Code sends usage telemetry by default; this is its documented opt-out.
  environment.variables.T3CODE_TELEMETRY_ENABLED = "false";

  # The only way in from outside: the VM joins the tailnet as its own tagged device.
  # It is not joined at first boot; `just flowdora clanker-join` supplies the auth key.
  services.tailscale.enable = true;
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 443 ];

  # The T3 server runs as the agent user, finds claude and codex on PATH and uses
  # their logins in that user's home. It listens on the box itself only and has
  # Tailscale publish it at https://<box>.<tailnet>.ts.net; until the box has joined
  # the tailnet it simply runs without that route.
  systemd.services.t3-server = {
    description = "T3 Code server";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "tailscaled.service"
    ];
    # A configuration update must not kill the agent sessions running under this
    # server; a new T3 version takes effect at the next boot or manual restart.
    restartIfChanged = false;
    environment.T3CODE_TELEMETRY_ENABLED = "false";
    # What the agent user would have in a terminal.
    path = [
      "/run/wrappers"
      "/etc/profiles/per-user/clanker"
      "/run/current-system/sw"
    ];
    serviceConfig = {
      User = "clanker";
      WorkingDirectory = "/home/clanker";
      ExecStart = "${t3-server}/bin/t3 serve --no-browser --tailscale-serve";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

  # Keeps the box in line with the repo. JsFlowdora publishes a committed copy of this
  # repo into a folder that Incus mounts read-only at ${hostShare}
  # (`just flowdora clanker-publish`). At boot, and whenever the host runs
  # `just flowdora clanker-update`, the box asks Incus for its own instance name and
  # switches to nixosConfigurations.<that name>, or to clanker-boxes-base if the flake
  # has no entry for it. A failed build leaves the running system untouched.
  systemd.services.clanker-apply = {
    description = "Apply this box's NixOS configuration from the host's published copy";
    # Enabled like any boot service, but ordered after multi-user.target so that it
    # runs once the boot has finished and nothing in the boot waits for it. Run as a
    # step of the boot itself, the switch below hung part-way through.
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "incus-agent.service" # mounts the share and provides /dev/incus/sock
      "multi-user.target"
    ];
    # The switch this unit performs must not stop or restart the unit itself.
    restartIfChanged = false;
    unitConfig.X-StopOnRemoval = false;
    serviceConfig.Type = "oneshot";
    environment = config.nix.envVars // {
      HOME = "/root";
    };
    path = [
      pkgs.coreutils
      pkgs.curl
      pkgs.gnused
      pkgs.gnutar
      pkgs.xz.bin
      pkgs.gzip
      pkgs.gitMinimal
      pkgs.util-linux # runuser
      config.nix.package.out
      config.system.build.nixos-rebuild
    ];
    script = ''
      share=${hostShare}
      # The Incus agent mounts the share shortly after it starts.
      for _ in $(seq 60); do
        [ -e "$share/revision" ] && break
        sleep 1
      done
      if [ ! -e "$share/revision" ]; then
        echo "Nothing published at $share; leaving the system as it is."
        exit 0
      fi

      name="$(curl -fsS --max-time 20 --unix-socket /dev/incus/sock http://incus/1.0/meta-data \
        | sed -n 's/^local-hostname: //p')"
      if [[ ! "$name" =~ ^[A-Za-z0-9-]+$ ]]; then
        echo "Could not read this box's instance name from Incus." >&2
        exit 1
      fi

      # Skip the evaluation, which takes a minute, when this revision is already applied.
      revision="$(cat "$share/revision")"
      applied=/var/lib/clanker-apply/applied
      if [ "$(cat "$applied" 2>/dev/null)" = "$name $revision" ]; then
        echo "$name already runs revision $revision."
        exit 0
      fi

      flake="path:$share/dotfiles"
      target="$(nix eval --raw "$flake#nixosConfigurations" \
        --apply "c: if c ? \"$name\" then \"$name\" else \"clanker-boxes-base\"")"
      echo "Applying $target at revision $revision to $name..."

      # Clean up by count, not by age: a box may be switched off for months. Keep the
      # running system plus a few to roll back to (five in all once the new one is
      # added); doing this before the switch also drops their boot-menu entries.
      nix-env --profile /nix/var/nix/profiles/system --delete-generations +4
      runuser -u clanker -- nix-env --delete-generations +4 \
        --profile /home/clanker/.local/state/nix/profiles/home-manager || true

      nixos-rebuild switch --flake "$flake#$target"

      # Frees what only the dropped systems needed. It also removes anything else in
      # the store that nothing points at, such as packages fetched by `nix shell`.
      nix-store --gc
      mkdir -p "$(dirname "$applied")"
      echo "$name $revision" > "$applied"
    '';
  };

  # The Incus image module turns sshd on; the host uses `incus exec` instead.
  services.openssh.enable = lib.mkForce false;
  networking.firewall.enable = true; # no inbound ports open
}
