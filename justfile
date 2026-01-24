default:
    @just --list

hostname := `hostname | cut -d "." -f 1`

### macos
# Build the nix-darwin system configuration without switching to it
[group('nix')]
[macos]
build target_host=hostname flags="":
  @echo "Building nix-darwin config..."
  nix --extra-experimental-features 'nix-command flakes'  build ".#darwinConfigurations.{{target_host}}.system" {{flags}}

# Build the nix-darwin config with the --show-trace flag set
[group('nix')]
[macos]
trace target_host=hostname: (build target_host "--show-trace")

# Build the nix-darwin configuration and switch to it
[group('nix')]
[macos]
switch target_host=hostname: (build target_host)
  @echo "switching to new config for {{target_host}}"
  sudo ./result/sw/bin/darwin-rebuild switch --flake ".#{{target_host}}"

# Activate a nix shell with latest home-manager from github
# nix shell github:nix-community/home-manager
# nix build ".#homeConfigurations.{{target_host}}.activationPackage" {{flags}}

### linux
# Build the home-manager configuration without switching to it (Fedora/non-NixOS)
[group('nix')]
[linux]
build target_host=hostname flags="":
  @echo "Building home-manager config..."
  nix --extra-experimental-features 'nix-command flakes'  build ".#linuxConfigurations.{{target_host}}.activationPackage" {{flags}}

# Build the home-manager config with the --show-trace flag set
[group('nix')]
[linux]
trace target_host=hostname: (build target_host "--show-trace")

# Build the home-manager configuration and switch to it (Fedora/non-NixOS)
[group('nix')]
[linux]
switch target_host=hostname:
  @echo "Switching to new home-manager config for {{target_host}}"
  nix run . -- switch --flake ".#{{target_host}}"

## NixOS specific (commented out)
# Build the NixOS configuration without switching to it
# [group('nix')]
# [linux]
# build target_host=hostname flags="":
# 	nixos-rebuild build --flake .#{{target_host}} {{flags}}

# # Build the NixOS config with the --show-trace flag set
# [group('nix')]
# [linux]
# trace target_host=hostname: (build target_host "--show-trace")

# # Build the NixOS configuration and switch to it.
# [group('nix')]
# [linux]
# switch target_host=hostname:
#   sudo nixos-rebuild switch --flake .#{{target_host}}

# ## colmena
# cbuild:
#   colmena build

# capply:
#   colmena apply

# Update flake inputs to their latest revisions
[group('nix')]
update:
  nix flake update


# Garbage collect old OS generations and remove stale packages from the nix store
gc:
  nix-collect-garbage --delete-older-than 7d
  nix-collect-garbage --delete-older-than 7d
  nix-store --gc

# bootstrap darwin system
[group('nix')]
[macos]
bootstrap:
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"


## manual command for initial bootstrapping
## sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
## nix --extra-experimental-features 'nix-command flakes' run nixpkgs#just
