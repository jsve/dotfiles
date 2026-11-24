default:
    @just --list

hostname := `hostname | cut -d "." -f 1`

# Recipes for the JsFlowdora machine only (LLM boot entry, clanker boxes); run as `just flowdora <recipe>`
mod flowdora 'hosts/linux/JsFlowdora/justfile'

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
switch target_host=hostname: (build target_host)
  @echo "switching to new config for {{target_host}}"
  ./result/activate

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

# Downloads Anthropic's release manifest for a channel ("latest" or "stable"), verifies
# its signature against the key pinned in home/modules/claude-code/release-key.asc, and
# only then replaces manifest.json. Afterwards run `just switch` on the Linux machines;
# only Claude Code is re-downloaded. (The Macs get Claude Code from Homebrew instead.)
[doc('Update only Claude Code (Linux) to the newest signed release; channel is "latest" or "stable"')]
[group('nix')]
update-claude channel="latest":
  #!/usr/bin/env bash
  set -euo pipefail
  BASE_URL="https://downloads.claude.ai/claude-code-releases"
  FINGERPRINT="31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE"
  DIR="{{justfile_directory()}}/home/modules/claude-code"
  if command -v gpg >/dev/null; then GPG=(gpg); else GPG=(nix run nixpkgs#gnupg --); fi
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  VERSION="$(curl -fsSL "$BASE_URL/{{channel}}")"
  if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: channel '{{channel}}' did not return a version number."
    exit 1
  fi
  curl -fsSL "$BASE_URL/$VERSION/manifest.zst.json" -o "$TMP/manifest.json"
  curl -fsSL "$BASE_URL/$VERSION/manifest.zst.json.sig" -o "$TMP/manifest.json.sig"
  export GNUPGHOME="$TMP/gnupg"
  mkdir -m 700 "$GNUPGHOME"
  "${GPG[@]}" --batch --quiet --import "$DIR/release-key.asc"
  if ! "${GPG[@]}" --batch --status-fd 1 --verify "$TMP/manifest.json.sig" "$TMP/manifest.json" 2>/dev/null \
      | grep -q "^\[GNUPG:\] VALIDSIG $FINGERPRINT "; then
    echo "Error: signature check failed for the $VERSION manifest; manifest.json left unchanged."
    exit 1
  fi
  # The signature only proves Anthropic signed this file at some point. Also require that
  # it is the manifest for the version we asked for, in the format the nix package expects,
  # so an older or different signed manifest served in its place is rejected.
  if ! grep -Fq "\"version\": \"$VERSION\"" "$TMP/manifest.json" \
      || ! grep -Fq '"binary": "claude.zst"' "$TMP/manifest.json"; then
    echo "Error: the signed manifest is not the expected one for $VERSION; manifest.json left unchanged."
    exit 1
  fi
  cp "$TMP/manifest.json" "$DIR/manifest.json"
  echo "✓ Claude Code manifest set to $VERSION ({{channel}}), signature verified. Run 'just switch' on the Linux machines to install."


# Garbage collect old OS generations and remove stale packages from the nix store
gc:
  nix-collect-garbage --delete-older-than 7d
  nix-collect-garbage --delete-older-than 7d
  nix-store --gc

# Bootstrap darwin system
[group('nix')]
[macos]
bootstrap:
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Set zsh as the default shell (Linux only)
# This adds the nix-installed zsh to /etc/shells and changes your default shell
# You'll need to log out and back in after running this for the change to take effect
[group('nix')]
[linux]
setup-shell:
  #!/usr/bin/env bash
  set -euo pipefail
  # Use the profile symlink, not the resolved /nix/store path: the store path
  # changes when zsh is rebuilt and is deleted by `just gc`, leaving no login shell.
  ZSH_PATH="$HOME/.nix-profile/bin/zsh"
  if [ ! -x "$ZSH_PATH" ]; then
    echo "Error: $ZSH_PATH not found. Run 'just switch' first."
    exit 1
  fi
  if [ "$SHELL" != "$ZSH_PATH" ]; then
    echo "Setting up zsh as default shell..."
    if ! grep -qx "$ZSH_PATH" /etc/shells 2>/dev/null; then
      echo "Adding $ZSH_PATH to /etc/shells (sudo required)"
      echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    echo "Changing default shell to zsh"
    chsh -s "$ZSH_PATH"
    echo "✓ Default shell changed to zsh. Please log out and back in."
  else
    echo "✓ Zsh is already your default shell"
  fi

# Configure PAM for hyprlock (required on non-NixOS)
# Nix's linux-pam is patched for NixOS paths, breaking auth on other distros.
# See: https://github.com/nix-community/home-manager/issues/7027
[group('nix')]
[linux]
setup-hyprlock:
  #!/usr/bin/env bash
  set -euo pipefail
  if [ -f /etc/pam.d/hyprlock ]; then
    echo "✓ /etc/pam.d/hyprlock already exists"
  else
    echo "Creating /etc/pam.d/hyprlock (sudo required)"
    echo "auth include login" | sudo tee /etc/pam.d/hyprlock >/dev/null
    echo "✓ PAM configured. hyprlock can now authenticate."
  fi


### vscode settings sync
# Settings are stored in configs/vscode/settings.json and synced via merge.
# Push: repo keys win, but runtime additions (from extensions) are preserved.
# Pull: current VS Code settings are saved back to the repo for committing.

vscode_settings := if os() == "macos" {
    home_directory() / "Library/Application Support/Code/User/settings.json"
} else {
    home_directory() / ".config/Code/User/settings.json"
}

# Merge repo vscode settings into VS Code (repo keys win, runtime additions preserved)
[group('vscode')]
vscode-push:
  #!/usr/bin/env bash
  set -euo pipefail
  repo_settings="{{justfile_directory()}}/configs/vscode/settings.json"
  vscode_settings="{{vscode_settings}}"

  if [ ! -f "$repo_settings" ]; then
    echo "Error: $repo_settings not found"
    exit 1
  fi

  # Read current VS Code settings (follows symlinks), default to empty object
  current=$(cat "$vscode_settings" 2>/dev/null || echo '{}')

  # Deep merge: current settings as base, repo settings override conflicts
  merged=$(echo "$current" | jq -s '.[0] * .[1]' - "$repo_settings")

  # Replace symlink with regular file if needed (leftover from home-manager)
  [ -L "$vscode_settings" ] && rm "$vscode_settings"

  mkdir -p "$(dirname "$vscode_settings")"
  echo "$merged" > "$vscode_settings"
  echo "VS Code settings updated (merged from repo)"

# Save current VS Code settings back to repo
[group('vscode')]
vscode-pull:
  #!/usr/bin/env bash
  set -euo pipefail
  repo_settings="{{justfile_directory()}}/configs/vscode/settings.json"
  vscode_settings="{{vscode_settings}}"

  if [ ! -f "$vscode_settings" ] && [ ! -L "$vscode_settings" ]; then
    echo "Error: No VS Code settings found at $vscode_settings"
    exit 1
  fi

  mkdir -p "$(dirname "$repo_settings")"
  jq '.' "$vscode_settings" > "$repo_settings"
  echo "VS Code settings saved to repo"

## manual command for initial bootstrapping
## sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
## nix --extra-experimental-features 'nix-command flakes' run nixpkgs#just
