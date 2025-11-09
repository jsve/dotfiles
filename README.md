# NIX and .files

## Initial Setup (or use bootstrap if just is installed)

Install [determinate nix](https://github.com/DeterminateSystems/nix-installer?tab=readme-ov-file)

This probably says:

```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

> [!CAUTION]
> If you want to proceed with nix-darwin after installing Nix: Please be prepared to answer with “no” when the determinate installer asks if you want to install Determinate Nix. As of today, Determinate Nix does not work well in combination with nix-darwin. For more information please refer to the nix-darwin README.


> [!INFO]
> If you are making changes to plists, make sure that terminal has full disk access in System Preferences -> Security & Privacy -> Privacy -> Full Disk Access

Use nix to build nix (we need just for that):

```
nix --extra-experimental-features 'nix-command flakes' run nixpkgs#just -- switch
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