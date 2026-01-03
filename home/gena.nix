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
      fzf
      bat    
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
      ll = "ls -l";
      la = "ls -la";
      gs = "git status";
      gd = "git diff";
      vd = "deactivate";
    };

    initContent = ''
      # Powerlevel10k instant prompt (must be near the top; must not print)
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # Load p10k config (XDG style)
      if [[ -f "${config.xdg.configHome}/p10k/p10k.zsh" ]]; then
        source "${config.xdg.configHome}/p10k/p10k.zsh"
      fi

      # EDITOR/VISUAL selection: GUI vs TTY/SSH
      if [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]]; then
        export EDITOR="code --wait"
        export VISUAL="code --wait"
      else
        export EDITOR="nano"
        export VISUAL="nano"
      fi

      # editor helper (works with "code --wait" too)
      ed() { ''${=EDITOR} "$@"; }

      va() {
          local dir=$(pwd)
          while [[ "$dir" != "/" ]]; do
              if [[ -f "$dir/.venv/bin/activate" ]]; then
                  source "$dir/.venv/bin/activate"
                  return
              fi
              dir=$(dirname "$dir")
          done
          echo "No virtual environment found."
      }      
    '';

    antidote = {
      enable = true;
      useFriendlyNames = true;
      plugins = [
        "getantidote/use-omz"
        "ohmyzsh/ohmyzsh path:lib"
        "ohmyzsh/ohmyzsh path:plugins/sudo"
        "ohmyzsh/ohmyzsh path:plugins/docker"
        "ohmyzsh/ohmyzsh path:plugins/kubectl"
        "ohmyzsh/ohmyzsh path:plugins/uv"

        "romkatv/powerlevel10k"
        "rupa/z"
        "mrjohannchang/fz.sh"
        "fdellwing/zsh-bat"
        "zsh-users/zsh-history-substring-search"
        "Aloxaf/fzf-tab"

        "zdharma-continuum/fast-syntax-highlighting kind:defer"
        "zsh-users/zsh-autosuggestions kind:defer"
        "romkatv/zsh-bench kind:path"
      ];
    };
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

  # ---- Keep ~ tidy by storing configs in .config ----
  xdg = {
    enable = true;
    configFile."p10k/p10k.zsh".source = ./p10k.zsh;
  };
}
