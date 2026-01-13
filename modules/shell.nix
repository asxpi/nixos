# Zsh and shell configuration
{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    # History settings
    histSize = 10000;
    histFile = "$HOME/.zsh_history";

    # Shell aliases
    shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
    };

    # Prompt configuration
    promptInit = ''
      # Blue colored prompt: [HH:MM:SS] [user@host path] $
      PROMPT='%B%F{#0055ff}[%b%f%D{%H:%M:%S}%B%F{#0055ff}]%b%f %B%F{#0055ff}[%b%f%n@%m %B%F{#0055ff}%~]%b%f %B%F{#0055ff}$%b%f '
    '';

    interactiveShellInit = ''
      # Prevent zsh-newuser-install wizard (creates marker file if missing)
      [[ ! -f ~/.zshrc ]] && touch ~/.zshrc

      # History options
      setopt SHARE_HISTORY
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_ALL_DUPS
      bindkey -e

      # Enhanced completion settings
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' rehash true

      # Key bindings for navigation
      bindkey "^[[H" beginning-of-line    # Home
      bindkey "^[[F" end-of-line          # End
      bindkey "^[[3~" delete-char         # Delete
      bindkey "^[[1;5C" forward-word      # Ctrl+Right
      bindkey "^[[1;5D" backward-word     # Ctrl+Left
      bindkey '^R' history-incremental-search-backward

      # Autosuggestions color
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

      # Environment variables
      export GOPATH=$HOME/.go
      export PATH=$PATH:$GOPATH/bin
      export PATH=$HOME/.local/bin:$PATH
      export PATH=$HOME/.opencode/bin:$PATH
      export PATH=$HOME/.cache/npm/global/bin:$PATH

      # Google Cloud SDK (if exists)
      if [ -f "$HOME/Code/gke/google-cloud-sdk/path.zsh.inc" ]; then
        source "$HOME/Code/gke/google-cloud-sdk/path.zsh.inc"
      fi
      if [ -f "$HOME/Code/gke/google-cloud-sdk/completion.zsh.inc" ]; then
        source "$HOME/Code/gke/google-cloud-sdk/completion.zsh.inc"
      fi

      # NVM (if you need it - consider using nixpkgs nodejs instead)
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
    '';
  };

  # Set GPG_TTY for all users
  environment.shellInit = ''
    export GPG_TTY=$(tty)
  '';

  # Shell aliases (available in all shells)
  environment.shellAliases = {
    nrs = ''export GPG_TTY=$(tty) && sudo nixos-rebuild switch --flake path:/etc/nixos && cd /etc/nixos && git add -A && git commit -S -m "Update: $(date +%Y-%m-%d_%H:%M)" || true && git push origin main'';
  };
}
