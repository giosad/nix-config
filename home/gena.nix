{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux  = pkgs.stdenv.isLinux;
in
{
  # Set once; don't bump casually.
  home.stateVersion = "25.11";

  # Packages (common + optional per-OS additions)
  home.packages = lib.mkMerge [
    (with pkgs; [
      git
      ripgrep
      fd
      jq
      tree
      htop
      curl
      wget
    ])
    (lib.mkIf isDarwin (with pkgs; [
      # macOS-only CLI tools if you want them
      # coreutils
    ]))
    (lib.mkIf isLinux (with pkgs; [
      # Linux-only user tools
    ]))
  ];

  # Default env; can be overridden by shell init logic below
  home.sessionVariables = {
    PAGER = "less -FR";
  };

  # ---- Shells ----
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      ll = "ls -la";
      gs = "git status";
      gd = "git diff";
    };

    initContent = ''
      # EDITOR/VISUAL selection: GUI vs TTY/SSH
      if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
        export EDITOR="code --wait"
        export VISUAL="code --wait"
      else
        export EDITOR="nano"
        export VISUAL="nano"
      fi

      alias ed="$EDITOR"
    '';
  };

  programs.bash.enable = true;

  # ---- Git ----
  programs.git = {
  enable = true;
  settings = {
    user.name = "Gena";
    user.email = "genaios@gmail.com";
    init.defaultBranch = "main";
  };
};

  # ---- SSH ----
programs.ssh = {
  enable = true;
  enableDefaultConfig = true;
};

  # ---- Keep ~/.config tidy ----
  xdg.enable = true;
}
