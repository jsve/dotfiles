## Touchpad config

started with: https://github.com/uginos/libinput-scroll-speed

used llm to create new script in /etc/libinput/plugins

robot installed evtest through `sudo dnf install evtest`.

robot gave up and fell back to using https://gitlab.com/warningnonpotablewater/libinput-config

commands:

Step 1: Install build dependencies

	sudo dnf install meson libinput-devel gcc

Step 2: Clone and build libinput-config

	git clone https://gitlab.com/warningnonpotablewater/libinput-config.git
	cd libinput-config
	meson build
	cd build
	ninja
	sudo ninja install

Step 3: Create the configuration file

	sudo nano /etc/libinput.conf

Add this content (adjust values to taste—lower = slower scrolling):

	scroll-factor=0.3

You can also set separate X/Y factors if needed:

	scroll-factor-x=0.3
	scroll-factor-y=0.3

## Bluetooth

issues with controllers disconnecting.

set FastConnectable = true (was = false and commented)

set TemporaryTimeout = 0 (was = 30 and commented)

## Hyprland (via Nix + home-manager)

Reference: https://gist.github.com/AntonFriberg/1dcb1ee6bf2c92c5f641a6f764d582d9

Installed 2026-02-05 via Nix + home-manager, replacing the previous Fedora COPR-based install.

### Why Nix instead of Fedora packages?

- **Isolation**: Nix packages + dependencies are self-contained in `/nix`, won't conflict with system packages
- **Reproducible**: Flake lock ensures exact versions across rebuilds
- **Easy rollback**: `home-manager generations` shows history, can switch back instantly
- **Unified config**: Single `just switch` updates everything (hyprland, walker, ghostty, etc.)

### How it works

Configuration is in the dotfiles repo:

- `home/modules/hyprland/hyprland.nix` - Hyprland window manager config
- `home/modules/hyprland/walker.nix` - Application launcher config
- `home/with-hyprland.nix` - Imports both modules
- `hosts/linux/JsFlowdora/default.nix` - Imports with-hyprland.nix
- `home/linux-common.nix` - nixGL setup for GPU access (mesa for AMD)

The `wayland.windowManager.hyprland` home-manager module handles:
- Installing hyprland (nixGL wrapping handled by `start-hyprland` at launch)
- Generating `~/.config/hypr/hyprland.conf` from nix settings
- Setting up xdg-desktop-portal-hyprland

**How nixGL works:** Since Hyprland 0.53.2, `start-hyprland` auto-detects Nix-built Hyprland on non-NixOS and wraps it via `execvp("nixGL", ...)`. We provide the `nixGL` binary by creating a wrapper script (in `linux-common.nix`) that delegates to `nixGLMesa` from home-manager's nixGL module. The GDM session entry uses `start-hyprland` instead of `Hyprland` directly, which also provides watchdog crash-restart. Other GUI apps (Waybar, Ghostty) still use home-manager's `config.lib.nixGL.wrap` for their own wrapping.

#### nixGL wrapper workaround (current as of 2026-02-07)

**The problem:** Hyprland's `start-hyprland` expects a binary named exactly `nixGL` in `$PATH`, but:
- Home-manager's nixGL module only installs specific wrappers like `nixGLMesa`, `nixGLNvidia`
- The nixGL flake provides `nixGLDefault` (auto-detect) but NOT a generic `nixGL` binary name
- There's no pure flake-based way to get a binary named `nixGL` without `--impure`

**Our solution:** In `linux-common.nix`, copy the nixGLIntel binary and rename it to `nixGL`:
```nix
(pkgs.runCommand "nixGL" { } ''
  mkdir -p $out/bin
  cp ${nixGL.packages.${pkgs.system}.nixGLIntel}/bin/* $out/bin/nixGL
'')
```
This mirrors what `nixGLCommon` does internally in the nixGL flake, but is pure (no --impure needed) because we use the mesa/intel wrapper directly instead of the auto-detecting nvidia version.

**Why this is necessary:**
1. `start-hyprland` hardcodes `execvp("nixGL", ...)` in `start/src/core/Instance.cpp`
2. The detection logic in `start/src/helpers/Nix.cpp` checks for `"nix"` flag in `Hyprland --version-json`
3. Home-manager's `targets.genericLinux.nixGL.installScripts = [ "mesa" ]` only creates `nixGLMesa`
4. The nixGL flake's `nixGLCommon` helper could create a `nixGL` binary, but requires impure evaluation

**When this might be fixed:**
- If Hyprland changes to look for `nixGLMesa`/`nixGLNvidia` directly (check `start/src/helpers/Nix.cpp`)
- If home-manager adds an option to create a generic `nixGL` alias
- If nixGL flake adds pure packages with the `nixGL` name

**Versions when this workaround was implemented:**
- Hyprland: 0.53.3 (nixpkgs)
- home-manager nixGL module: PR #5355 (merged Oct 2024)
- nixGL: rolling (github:nix-community/nixGL)

**Alternative (not recommended):** Install nixGL imperatively via `nix profile install github:nix-community/nixGL --impure`. This provides `nixGLDefault` but defeats the purpose of pure flake-based config.

### GDM Session Entry

Create the desktop entry so Hyprland appears in GDM login screen:

```bash
sudo tee /usr/share/wayland-sessions/hyprland.desktop << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor (Nix)
Exec=/home/johan/.nix-profile/bin/start-hyprland
Type=Application
EOF
```

### Key diversions from the reference guide

| Guide says | We do instead | Why |
|------------|---------------|-----|
| Create `~/.config/home-manager/` | Use `~/repos/dotfiles/` | Already have a flake-based dotfiles repo |
| Use alacritty | Keep ghostty | Personal preference |
| Install via `home-manager switch --flake ~/.config/home-manager` | Use `just switch` | Integrated with existing workflow |
| `nixGL.packages = nixGL.packages` at module level | `targets.genericLinux.nixGL.packages = nixGL.packages` | Correct path for current home-manager |

### Useful commands

```bash
# Rebuild and apply config changes
just switch

# Check Hyprland version
Hyprland --version

# Update all nix inputs (including hyprland)
just update && just switch

# Rollback to previous generation
home-manager generations  # list generations
/nix/store/xxx-home-manager-generation/activate  # activate a previous one
```

### Uninstalling

To fully remove Hyprland and Nix:

```bash
# Remove GDM session entry
sudo rm /usr/share/wayland-sessions/hyprland.desktop

# Uninstall everything via Determinate Nix Installer
/nix/nix-installer uninstall
```

This removes Nix, home-manager, and all packages cleanly.

---

Previous DNF-based install reverted 2026-02-05. See REVERTED section below.

### Reverting Hyprland (DNF version)

Remove hyprland packages (only removes what was actually installed, not base system packages):

```
sudo dnf remove hyprland sddm kitty waybar hyprpolkitagent pavucontrol blueman nm-connection-editor-desktop
```

Disable copr repos:

```
sudo dnf copr disable lionheartp/Hyprland
sudo dnf copr disable solopasha/hyprland
```

Remove config directories:

```
rm -rf ~/.config/hypr
rm -rf ~/.config/kitty
```

Remove leftover data/cache directories:

```
rm -rf ~/.local/share/hyprland
rm -rf ~/.cache/kitty
rm -rf ~/.cache/"Hyprland Polkit Agent"
```

### 🪦 REVERTED - Hyprland

followed this: https://discussion.fedoraproject.org/t/tutorial-fedora-43-install-hyprland-from-scratch/168386

```
sudo dnf copr enable solopasha/hyprland
```

```
sudo dnf install hyprland sddm tuned tuned-ppd kitty waybar hyprpolkitagent nautilus pavucontrol alsa-sof-firmware alsa-utils blueman NetworkManager-wifi iwl* nm-connection-editor-desktop gvfs gvfs-mtp
```

repo seems dead. according to https://github.com/solopasha/hyprlandRPM/issues/47

did
```
sudo dnf copr disable solopasha/hyprland 
sudo dnf copr enable lionheartp/Hyprland 
sudo dnf distro-sync
sudo dnf upgrade --refresh
``` 

instead, and then again

```
sudo dnf install hyprland sddm tuned tuned-ppd kitty waybar hyprpolkitagent nautilus pavucontrol alsa-sof-firmware alsa-utils blueman NetworkManager-wifi iwl* nm-connection-editor-desktop gvfs gvfs-mtp
```

**Install notes:**

Verified actual installation via DNF history (transaction 7, 2026-01-11).

Many packages from the tutorial command were already installed from the initial system setup (transaction 2, 2025-10-23):
- `nautilus` - installed as part of GNOME base
- `gvfs` and `gvfs-mtp` - installed with GNOME file system support
- `alsa-sof-firmware` and `alsa-utils` - installed with audio support
- `NetworkManager-wifi` - installed with network support
- `iwl*` (all Intel WiFi firmware packages) - installed with network drivers
- `tuned` and `tuned-ppd` - installed as dependencies/weak dependencies
- `nm-connection-editor` (base package) - installed as weak dependency

Only these packages were actually installed:
```
hyprland sddm kitty waybar hyprpolkitagent pavucontrol blueman nm-connection-editor-desktop
```

This installed 59 packages total including dependencies and weak dependencies:
- Core Hyprland stack: hyprland, hyprland-qt-support, hyprland-uwsm, xdg-desktop-portal-hyprland
- Supporting libs: aquamarine, hyprcursor, hyprgraphics, hyprutils, hyprwire, hyprlang
- Tools: wofi, wlr-randr, brightnessctl, hyprpicker, grim, slurp, ripgrep
- UI components: nwg-panel, fontawesome fonts

**End install notes**

this guide has some claims about gnome and hyprland: https://dev.to/renhiyama/how-to-dualboot-hyprland-with-gnome-desktops-on-linux-1pa4

looks like:
 - we dont need sddm.
 - we don't need polkit-gnome. hyprpolkitagent seems fine

 back to OG guide:
 
 update hyprland config to have this in autostart:

```
exec-once = $terminal
exec-once = waybar
exec-once = systemctl --user start hyprpolkitagent
```

#### walker / elephant

initially installed through dnf. reverted and added to nix config.

#### 🪦 REVERTED - walker / elephant

add walker:

```
sudo dnf copr enable errornointernet/walker
sudo dnf install walker
```

install elephant from source https://github.com/abenz1267/elephant

make sure go is installed: `sudo dnf install golang`

add go to path in bashrc: `export PATH="$HOME/go/bin:$PATH"`

clone and build elephant:

```
git clone https://github.com/abenz1267/elephant.git
cd elephant
go build
mkdir -p ~/go/bin
cp elephant ~/go/bin/
```

build elephant providers:

```
cd providers/desktopapplications
go build -buildmode=plugin
mkdir -p ~/.config/elephant/providers
cp desktopapplications.so ~/.config/elephant/providers/

cd ../providerlist
go build -buildmode=plugin
cp providerlist.so ~/.config/elephant/providers/
```

enable and start elephant service:

```
elephant service enable
```

modify the service unit via `systemctl --user edit elephant.service` to have:

```
[Service]
ExecStart=
ExecStart=%h/go/bin/elephant
```

start the service:

```
systemctl --user start elephant.service
```

add keybinding in hyprland.conf:

```
bind = $mainMod, SPACE, exec, walker
```

elephant stores data in:
- `~/.cache/elephant/` - usage history/frecency data (`.gob` files)
- `~/.config/elephant/providers/` - the plugin `.so` files

#### Reverting walker / elephant

stop and disable elephant service:

```
systemctl --user stop elephant.service
systemctl --user disable elephant.service
```

remove elephant service files:

```
rm -f ~/.config/systemd/user/elephant.service
rm -rf ~/.config/systemd/user/elephant.service.d
systemctl --user daemon-reload
```

remove elephant binary and data:

```
rm -f ~/go/bin/elephant
rm -rf ~/.config/elephant
rm -rf ~/.cache/elephant
```

remove walker package and copr repo:

```
sudo dnf remove walker
sudo dnf copr disable errornointernet/walker
```

remove hyprland keybindings and autostart (edit ~/.config/hypr/hyprland.conf):
- remove `exec-once = systemctl --user start elephant`
- remove `bind = $mainMod, SPACE, exec, walker` (or similar)

TODO: find a way to boot back into gnome
TODO: find out what to do with uwsm
TODO: gnome apps look shitty. what to do?

### Gnome/hyprland compat

add to ~/.vscode/argv.json -> "password-store": "gnome-libsecret"