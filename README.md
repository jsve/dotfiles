# NIX and .files

## Initial Setup (or use bootstrap if just is installed)

Install [determinate nix](https://github.com/DeterminateSystems/nix-installer?tab=readme-ov-file)

This probably says:

```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

> [!CAUTION]
> If you want to proceed with nix-darwin after installing Nix: Please be prepared to answer with “no” when the determinate installer asks if you want to install Determinate Nix. As of today, Determinate Nix does not work well in combination with nix-darwin. For more information please refer to the nix-darwin README.


> [!NOTE]
> If you are making changes to plists, make sure that terminal has full disk access in System Preferences -> Security & Privacy -> Privacy -> Full Disk Access

Use nix to build nix (we need just for that):

```
nix --extra-experimental-features 'nix-command flakes' run nixpkgs#just -- switch
```

or:

```
nix-shell -p just
just build
```

## Repository Structure

This repository manages system and user configurations across macOS (via nix-darwin) and Linux (via standalone home-manager on Fedora). The structure is designed to share common configurations while allowing platform-specific customizations.

### Directory Layout

```
├── flake.nix                    # Main flake configuration defining systems
├── justfile                     # Task runner with build, switch, and utility commands
├── lib/
│   └── helpers.nix              # mkDarwin and mkLinux functions for system configs
├── pkgs/
│   └── t3-server/               # T3 Code headless server, pinned to an upstream release
├── hosts/
│   ├── common/
│   │   ├── system-packages-list.nix  # Shared package list (system-level on darwin/nixos, user-level on fedora)
│   │   ├── system-packages.nix       # Wrapper for environment.systemPackages (darwin/nixos only)
│   │   ├── darwin-system.nix         # nix-darwin specific system config (homebrew, system settings)
│   │   └── darwin-dock.nix           # Default dock configuration for darwin
│   ├── darwin/
│   │   └── <hostname>/               # Host-specific darwin overrides
│   ├── linux/
│   │   └── <hostname>/               # Host-specific linux overrides (JsFlowdora also has its own justfile)
│   └── vms/
│       └── clanker-boxes/            # NixOS guests for sandboxed coding agents, plus their Incus and firewall setup
└── home/
    ├── core.nix                 # Shell setup and CLI tools for every machine, including the clanker-box VMs
    ├── common.nix               # Shared home-manager config for my own machines (imports core.nix)
    ├── darwin-common.nix        # Darwin-specific home-manager config
    ├── linux-common.nix         # Linux-specific home-manager config (imports system-packages-list)
    └── modules/
        ├── direnv.nix
        ├── vscode.nix
        └── zsh.nix
```

### How It Works

**macOS (nix-darwin):**
- System-level packages via `environment.systemPackages` (from `system-packages-list.nix`)
- System configuration (homebrew, system settings) in `darwin-system.nix`
- User packages and programs in `home/common.nix`
- Uses nix-darwin integration for seamless system/user management

**Linux/Fedora (standalone home-manager):**
- No system-level package management (no `environment.systemPackages`)
- Imports `system-packages-list.nix` into `home.packages` (user-level installation)
- Requires explicit PATH setup via `systemd.user.sessionVariables`
- Everything managed at user-level through home-manager

**Clanker boxes (sandboxed coding-agent VMs on JsFlowdora):**
- NixOS guests built from `hosts/vms/clanker-boxes/base.nix` and run as Incus VMs
- A guest can reach the public internet and nothing on the host, LAN or other guests; this is enforced twice, by an Incus network ACL and by firewalld
- Managed with `just flowdora clanker-host-setup`, `clanker-image`, `clanker-launch <name>`, `clanker-publish` and `clanker-update [name]`
- `clanker-tailnet-join <name>` puts a box on the tailnet as its own tagged device and `clanker-t3-pair <name>` prints a link that pairs the T3 app with it
- JsFlowdora builds one starter image. After that each box rebuilds itself, at boot and on `clanker-update`, from a committed copy of this repo that `clanker-publish` places in a folder mounted read-only into the boxes; boxes never pull from GitHub
- A box applies `nixosConfigurations.<its Incus name>` from `flake.nix`, or `clanker-boxes-base` if it has no entry of its own
- Guests import `home/core.nix`, so anything added there lands in every agent VM
- Secrets never go in this repo or in anything the flake reads; they are typed at a prompt and streamed into a running VM. The one exception is optional: `clanker-authkey` keeps a Tailscale auth key in a root-only file on the host, meant for a tailnet with device approval on

**Shared Configuration:**
- `system-packages-list.nix` defines packages once, used differently per platform
- `home/common.nix` contains cross-platform user configuration
- Platform-specific configs in `darwin-common.nix` and `linux-common.nix`

### Key Commands

```bash
just build            # Build configuration without switching
just switch           # Build and activate configuration
just update           # Update flake inputs
just update-claude    # Update only Claude Code (Linux) to the newest signed release
just update-t3        # Update the pinned T3 Code server used by the clanker boxes
just --list flowdora  # Recipes that only apply to the JsFlowdora machine
just gc               # Run garbage collection
```

## Stuff to remember

### Brew

Nix-homebrew can install [Homebrew](https://brew.sh/) (if you already installed it though this command and have `autoMigrate` enabled):

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Youtubers

 - https://www.youtube.com/watch?v=qUmZtC6ts0M


### Other configs

 - Alexander - https://github.com/phelian/dotfiles/
 - Random youtuber - https://github.com/ironicbadger/nix-config
 - Some swedich enterprise dude - https://github.com/HestHub/nixos/blob/main/home/darwin.nix
 - did not read (but likely relevant) - https://github.com/wimpysworld/nix-config
 - another i did not read - https://github.com/shayne/nixos-config/tree/main
 - yet another i did not read - https://github.com/mitchellh/nixos-config