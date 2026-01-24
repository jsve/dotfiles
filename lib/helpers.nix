{
  inputs,
  outputs,
  stateVersion,
  ...
}:
{
  mkDarwin =
    {
      hostname,
      username,
      system ? "aarch64-darwin",
    }:
    let
      inherit (inputs.nixpkgs) lib;
      unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
      customConfPath = ./../hosts/darwin/${hostname};
      customConf =
        if builtins.pathExists (customConfPath) then
          (customConfPath + "/default.nix")
        else
          ./../hosts/common/darwin-common-dock.nix;
    in
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = {
        inherit
          system
          inputs
          username
          unstablePkgs
          ;
      };
      modules = [
        ../hosts/common/common-packages.nix
        ../hosts/common/darwin-common.nix
        customConf
        inputs.mac-app-util.darwinModules.default
        inputs.home-manager.darwinModules.home-manager
        {
          networking.hostName = hostname;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.sharedModules = [
            inputs.mac-app-util.homeManagerModules.default
          ];
          home-manager.users.${username} = {
            imports = [
              ./../home/common.nix
            ]
            ++ lib.optionals (builtins.pathExists ./../home/${username}.nix) [
              ./../home/${username}.nix
            ];
          };
        }
        inputs.nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            autoMigrate = true;
            mutableTaps = true;
            user = "${username}";
            taps = with inputs; {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "homebrew/homebrew-bundle" = homebrew-bundle;
            };
          };
        }

      ];
    };

  mkLinux =
    {
      hostname,
      username,
      system ? "x86_64-linux",
    }:
    let
      inherit (inputs.nixpkgs) lib;
      unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
      customConfPath = ./../hosts/linux/${hostname};
      customConf =
        if builtins.pathExists (customConfPath) then
          (customConfPath + "/default.nix")
        else
          ./../hosts/common/linux-common.nix;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      specialArgs = {
        inherit
          system
          inputs
          username
          unstablePkgs
          ;
      };
      modules = [
        ../hosts/common/common-packages.nix
        ../hosts/common/linux-common.nix
        customConf
        inputs.home-manager.modules.home-manager
        {
          networking.hostName = hostname;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.sharedModules = [ ];
          home-manager.users.${username} = {
            imports = [
              ./../home/common.nix
            ]
            ++ lib.optionals (builtins.pathExists ./../home/${username}.nix) [
              ./../home/${username}.nix
            ];
          };
        }
      ];
    };

}
