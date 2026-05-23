{ config, pkgs, lib, isLTWorkDevice ? false, ... }:

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
      htop
      btop
      curl
      wget
      fzf
      bat
      tree
      nnn
      ncdu
      tmux
      gitstatus   # used by powerlevel10k via $GITSTATUS_DAEMON (avoids p10k's broken auto-download path)
    ])
    (lib.mkIf isDarwin (with pkgs; [
      # macOS-only CLI tools if you want them
      coreutils
    ]))
    (lib.mkIf isLinux (with pkgs; [
      nodejs_22
      # Linux-only user tools
    ]))
  ];

  programs.tealdeer = {
    enable = true;
    enableAutoUpdates = true;
  };

  # Default env; can be overridden by shell init logic below
  home.sessionVariables = {
    PAGER = "less -FR";
    NPM_CONFIG_PREFIX = "$HOME/.local";
    PNPM_HOME = "$HOME/.local/share/pnpm";

    # Point powerlevel10k at the nix-provided gitstatusd (v1.5.5).
    # p10k's auto-download path is broken: its build.info wants v1.5.5 but
    # install.info still pins all platforms to v1.5.4, and there's no v1.5.5
    # binary release upstream — every shell start fails the version check.
    GITSTATUS_DAEMON = "${pkgs.gitstatus}/bin/gitstatusd";
  };

  # Add ~/.local/bin to PATH
  home.sessionPath = [
    "$HOME/.local/bin"
    "$PNPM_HOME"
  ];

  # ---- Shells ----
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = config.home.homeDirectory;

    shellAliases = {
      ls = "ls -Fh --color=auto --group-directories-first";
      ll = "ls -l";
      la = "ls -la";
      gs = "git status";
      gd = "git diff";
      vd = "deactivate";
    };

    initContent = lib.mkMerge [
      # p10k instant prompt must be first (before any output)
      (lib.mkOrder 100 ''
        # Powerlevel10k instant prompt
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')

      # Rest of init content at default priority
      '' 
        # Load p10k config (XDG style)
        if [[ -f "${config.xdg.configHome}/p10k/p10k.zsh" ]]; then
          source "${config.xdg.configHome}/p10k/p10k.zsh"
        fi

        # Disable magic functions to avoid [[200 markers on pasted text
        DISABLE_MAGIC_FUNCTIONS=true
        
        # EDITOR/VISUAL selection
        ${if isDarwin then ''
          if command -v cot &>/dev/null; then
            export EDITOR="cot"
            export VISUAL="cot"
          else
            export EDITOR="nano"
            export VISUAL="nano"
          fi
        '' else ''
          # Linux: GUI editor if display available
          if [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]]; then
            export EDITOR="code --wait"
            export VISUAL="code --wait"
          else
            export EDITOR="nano"
            export VISUAL="nano"
          fi
        ''}

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

        # Completion polish (case-insensitive, colored). fzf-tab honors these.
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"

        # Esc-Esc to prepend/toggle sudo on the current line
        sudo-command-line() {
          [[ -z $BUFFER ]] && zle up-history
          if [[ $BUFFER == sudo\ * ]]; then
            LBUFFER="''${LBUFFER#sudo }"
          else
            LBUFFER="sudo $LBUFFER"
          fi
        }
        zle -N sudo-command-line
        bindkey -M emacs '\e\e' sudo-command-line
        bindkey -M viins '\e\e' sudo-command-line
        bindkey -M vicmd '\e\e' sudo-command-line

      ''
    ];

    antidote = {
      enable = true;
      useFriendlyNames = true;
      plugins = [
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
    lfs.enable = true;
    settings = {
      user.name = "Gennadi Iosad";
      user.email = if isLTWorkDevice then "gena@lightricks.com" else "genaios@gmail.com";
      init.defaultBranch = "main";
      alias = {
        pushuf = "!git push -u origin --force-with-lease $(git symbolic-ref --short HEAD)";
        pushu = "!git push -u origin $(git symbolic-ref --short HEAD)";
        st = "status";
        co = "checkout";
        log-graph = "log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'";
        log-graph-all = "log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --all";
        clone-rec = "clone --recurse-submodules";
        clean-hard = "!git reset --hard && git clean -ffdx";
        amend = "commit --no-edit --amend";
        sumu = "submodule update --init --recursive";
        unstage-all = "restore --staged .";
        discard = "restore";
      };
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;

    # optional
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  # ---- Keep ~ tidy by storing configs in .config ----
  xdg = {
    enable = true;
    configFile = {
      "p10k/p10k.zsh".source = ./p10k.zsh;
    } // lib.optionalAttrs isDarwin {
      "karabiner/karabiner.json".source = ./karabiner.json;
    };
  };

  # ---- Scripts ----
  home.file = lib.mkMerge [
    {
      ".local/bin/zshrc-diff-run" = {
        source = ./zshrc-diff-run;
        executable = true;
      };
    }
    (lib.mkIf isDarwin {
      ".local/bin/say_ready" = {
        source = ./say_ready;
        executable = true;
      };
      ".local/bin/check_internet" = {
        source = ./check_internet;
        executable = true;
      };
    })
  ];
}
