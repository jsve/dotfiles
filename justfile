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

# Add a GRUB boot entry with kernel parameters for vLLM/LLM workloads on AMD Strix Halo
# This creates a separate boot menu entry so you can choose when to boot with GPU memory settings
# Parameters: iommu=pt, amdgpu.gttsize=126976, ttm.pages_limit=32505856 (124 GiB for iGPU)
# Source: https://github.com/kyuz0/amd-strix-halo-vllm-toolboxes
[group('llm')]
[linux]
prepare_grub_for_llm:
  #!/usr/bin/env bash
  set -eu
  
  ENTRIES_DIR="/boot/loader/entries"
  KERNEL_VERSION="$(uname -r)"
  KERNEL="/boot/vmlinuz-$KERNEL_VERSION"
  TITLE="Fedora Linux ($KERNEL_VERSION) vLLM Mode"
  ARGS="iommu=pt amdgpu.gttsize=126976 ttm.pages_limit=32505856"
  # Use all-zeros machine-id prefix so it sorts AFTER regular Fedora entries (GRUB sorts descending)
  # grubby requires a 32-char hex prefix to recognize the entry
  VLLM_ENTRY="$ENTRIES_DIR/00000000000000000000000000000000-vllm-$KERNEL_VERSION.conf"
  
  # Check if a vLLM Mode entry already exists (need sudo to read the directory)
  if sudo test -f "$VLLM_ENTRY"; then
    echo "A vLLM Mode GRUB entry already exists: $VLLM_ENTRY"
    echo "Run 'just remove_grub_llm' first if you want to recreate it."
    exit 1
  fi
  
  # Get the default boot entry index before we make changes
  DEFAULT_INDEX=$(sudo grubby --default-index)
  
  echo "Creating GRUB boot entry: $TITLE"
  echo "Based on default entry (index $DEFAULT_INDEX)"
  echo "Kernel: $KERNEL"
  echo "Extra args: $ARGS"
  echo ""
  
  # --copy-default: copy args/initrd from default entry
  # --add-kernel: required by grubby, points to same kernel
  # --title: our custom title with "vLLM Mode" marker
  # --args: additional args to append
  # Note: grubby returns non-zero when entry exists but still creates the custom file
  sudo grubby --copy-default \
    --add-kernel="$KERNEL" \
    --title="$TITLE" \
    --args="$ARGS" || true
  
  # Find the entry grubby just created (has ~custom in the name)
  CREATED_ENTRY=$(sudo find "$ENTRIES_DIR" -name "*${KERNEL_VERSION}*custom*" -type f | head -1)
  
  if [ -z "$CREATED_ENTRY" ]; then
    echo "Error: Could not find the created entry file."
    exit 1
  fi
  
  # Rename to all-zeros machine-id prefix so it sorts after regular Fedora entries
  sudo mv "$CREATED_ENTRY" "$VLLM_ENTRY"
  echo "Renamed: $(basename "$CREATED_ENTRY") -> $(basename "$VLLM_ENTRY")"
  
  # Restore the original default (grubby may have changed it)
  sudo grubby --set-default-index="$DEFAULT_INDEX"
  
  echo ""
  echo "✓ GRUB entry created: $TITLE"
  echo "✓ Entry file: $VLLM_ENTRY"
  echo "✓ Default boot entry unchanged (index $DEFAULT_INDEX)"
  echo ""
  echo "On next boot, select '$TITLE' from the GRUB menu to use GPU memory settings."
  echo "After booting into vLLM Mode, verify with: just verify_grub_llm"

# Remove the vLLM Mode GRUB boot entry
# Removes entries with "00000000000000000000000000000000-vllm-" prefix (and legacy entries)
[group('llm')]
[linux]
remove_grub_llm:
  #!/usr/bin/env bash
  set -euo pipefail
  
  ENTRIES_DIR="/boot/loader/entries"
  # Find current (00..00-vllm-) and legacy (0-vllm-, zzz-vllm-) entries
  VLLM_ENTRIES=$(sudo find "$ENTRIES_DIR" -maxdepth 1 -name "00000000000000000000000000000000-vllm-*.conf" -o -name "0-vllm-*.conf" -o -name "zzz-vllm-*.conf" 2>/dev/null || true)
  
  if [ -z "$VLLM_ENTRIES" ]; then
    echo "No vLLM Mode GRUB entries found."
    exit 0
  fi
  
  for entry in $VLLM_ENTRIES; do
    echo "Removing: $entry"
    sudo rm "$entry"
  done
  
  echo "✓ vLLM Mode GRUB entry removed."

# Verify that vLLM kernel parameters are active (run after booting into vLLM Mode)
[group('llm')]
[linux]
verify_grub_llm:
  #!/usr/bin/env bash
  set -euo pipefail
  
  echo "Checking kernel command line for vLLM parameters..."
  echo ""
  
  CMDLINE=$(cat /proc/cmdline)
  MISSING=0
  
  for param in "iommu=pt" "amdgpu.gttsize=126976" "ttm.pages_limit=32505856"; do
    if echo "$CMDLINE" | grep -q "$param"; then
      echo "✓ $param"
    else
      echo "✗ $param (missing)"
      MISSING=1
    fi
  done
  
  echo ""
  if [ $MISSING -eq 0 ]; then
    echo "All vLLM kernel parameters are active!"
  else
    echo "Some parameters are missing. Did you boot into the vLLM Mode entry?"
  fi

# Set zsh as the default shell (Linux only)
# This adds the nix-installed zsh to /etc/shells and changes your default shell
# You'll need to log out and back in after running this for the change to take effect
[group('nix')]
[linux]
setup-shell:
  #!/usr/bin/env bash
  set -euo pipefail
  ZSH_PATH="$(readlink -f ~/.nix-profile/bin/zsh)"
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


## manual command for initial bootstrapping
## sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
## nix --extra-experimental-features 'nix-command flakes' run nixpkgs#just
