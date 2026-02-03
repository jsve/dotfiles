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

## Hyprland

followed this: https://discussion.fedoraproject.org/t/tutorial-fedora-43-install-hyprland-from-scratch/168386

```
sudo dnf copr enable solopasha/hyprland
```

```
sudo dnf install hyprland sddm tuned tuned-ppd kitty waybar hyprpolkitagent nautilus pavucontrol alsa-sof-firmware alsa-utils blueman NetworkManager-wifi iwl* nm-connection-editor-desktop gvfs gvfs-mtp
```

repo seems dead. according to https://github.com/solopasha/hyprlandRPM/issues/47

did
´´´
sudo dnf copr disable solopasha/hyprland 
sudo dnf copr enable lionheartp/Hyprland 
sudo dnf distro-sync
sudo dnf upgrade --refresh
``` 

instead, and then again

```
sudo dnf install hyprland sddm tuned tuned-ppd kitty waybar hyprpolkitagent nautilus pavucontrol alsa-sof-firmware alsa-utils blueman NetworkManager-wifi iwl* nm-connection-editor-desktop gvfs gvfs-mtp
```

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

### Addon rabbit holes

#### walker / elephant

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
TODO: find a way to boot back into gnome
TODO: find out what to do with uwsm
TODO: gnome apps look shitty. what to do?

### Gnome/hyprland compat

add to ~/.vscode/argv.json -> "password-store": "gnome-libsecret"