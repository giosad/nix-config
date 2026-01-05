{ pkgs, self, ... }:

{
  # Let Determinate Nix manage the daemon
  nix.enable = false;

  # System packages (darwin-wide)
  environment.systemPackages = with pkgs; [
    htop
    btop
  ];

  # Use system zsh (macOS default)
  # programs.zsh.enable = true;

  # Set Git commit hash for darwin-version
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # Platform
  nixpkgs.hostPlatform = "aarch64-darwin";

  # # macOS system defaults
  # system.defaults = {
  #   NSGlobalDomain = {
  #     AppleShowAllExtensions = true;
  #     # Faster key repeat
  #     KeyRepeat = 2;
  #     InitialKeyRepeat = 15;
  #   };
  #
  #   dock = {
  #     autohide = true;
  #     show-recents = false;
  #     tilesize = 48;
  #   };
  #
  #   finder = {
  #     AppleShowAllExtensions = true;
  #     ShowPathbar = true;
  #     FXEnableExtensionChangeWarning = false;
  #   };
  #
  #   trackpad = {
  #     Clicking = true;
  #     TrackpadRightClick = true;
  #   };
  # };

  # # Keyboard settings
  # system.keyboard = {
  #   enableKeyMapping = true;
  #   remapCapsLockToEscape = false;
  # };

  # Disable PAM management (SIP prevents modifying /etc/pam.d/)
  security.pam.services.sudo_local.enable = false;
}
