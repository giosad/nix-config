{ pkgs, self, ... }:

{
  # Let Determinate Nix manage the daemon
  nix.enable = false;

  # System packages (darwin-wide)
  environment.systemPackages = with pkgs; [
    marp-cli
    monolith
  ];

  # Use system zsh (macOS default)
  # Strip /etc/zshrc down — home-manager's ~/.zshrc handles compinit and the
  # prompt (powerlevel10k). Leaving the defaults on means promptinit, compinit,
  # and bashcompinit all run before ~/.zshrc, adding ~2.5s to interactive
  # startup before doing anything we keep.
  programs.zsh = {
    enable = true;
    enableCompletion = false;
    enableBashCompletion = false;
    promptInit = "";
  };

  # Set Git commit hash for darwin-version
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # Required for user-specific system.defaults
  system.primaryUser = "gena";

  # Platform
  nixpkgs.hostPlatform = "aarch64-darwin";

  # macOS system defaults
  system.defaults = {
    NSGlobalDomain = {
      # Faster key repeat
      KeyRepeat = 2;
      InitialKeyRepeat = 30;
      NSAutomaticQuoteSubstitutionEnabled = false;

      # Menubar icon spacing (tighter layout)
      NSStatusItemSpacing = 12;
      NSStatusItemSelectionPadding = 8;
    };
  
    dock = {
      autohide = true;
      show-recents = false;
      tilesize = 48;
    };
  
    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      FXEnableExtensionChangeWarning = false;
    };
  };

  # (SentinelOne blocks nix-managed installation) 
  # Karabiner Elements: config managed by home-manager, app installed manually
  # brew install --cask karabiner-elements
  
  # Disable PAM management (SIP prevents modifying /etc/pam.d/)
  security.pam.services.sudo_local.enable = false;
  # do it yourself with
  # sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local
  # sudo sed -i '' '/pam_tid\.so/s/^[[:space:]]*#[[:space:]]*//' /etc/pam.d/sudo_local
}
