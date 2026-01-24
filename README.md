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
├── hosts/
│   ├── common/
│   │   ├── system-packages-list.nix  # Shared package list (system-level on darwin/nixos, user-level on fedora)
│   │   ├── system-packages.nix       # Wrapper for environment.systemPackages (darwin/nixos only)
│   │   ├── darwin-system.nix         # nix-darwin specific system config (homebrew, system settings)
│   │   └── darwin-dock.nix           # Default dock configuration for darwin
│   ├── darwin/
│   │   └── <hostname>/               # Host-specific darwin overrides
│   └── linux/
│       └── <hostname>/               # Host-specific linux overrides
└── home/
    ├── common.nix               # Shared home-manager config (user packages, programs)
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

**Shared Configuration:**
- `system-packages-list.nix` defines packages once, used differently per platform
- `home/common.nix` contains cross-platform user configuration
- Platform-specific configs in `darwin-common.nix` and `linux-common.nix`

### Key Commands

```bash
just build            # Build configuration without switching
just switch           # Build and activate configuration
just update           # Update flake inputs
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