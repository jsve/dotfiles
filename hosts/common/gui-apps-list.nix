# Shared GUI applications manifest
# Lists apps as strings that each platform can map to their package managers
# - Darwin (macOS): maps to Homebrew cask names
# - Linux: maps to nix package names (when available)
{
  # Apps that should be installed on both macOS and Linux
  common = [
    "ghostty"
  ];

  # Linux-specific GUI apps
  linux = [
  ];

  # Linux GUI apps that need OpenGL wrapping (nixGL)
  linux-opengl-apps = [
    "ghostty"
  ];

  # Darwin-specific GUI apps (Homebrew casks)
  darwin = [
    "1password"
    "google-chrome"
    # "karabiner-elements"
    "fluor"
    "lm-studio"
    "microsoft-excel"
    "mongodb-compass"
    # "notion"
    # "obsidian"
    # "orbstack" # managed by home-manager
    # "signal"
    # "slack" # managed by home-manager
    "steam"
    # "wireshark"
    # "visual-studio-code" # managed by home-manager
    "vlc"
  ];
}
