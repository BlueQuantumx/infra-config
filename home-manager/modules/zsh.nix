{ ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    enableCompletion = true;

    shellAliases = {
      ls = "ls -FGh";
      ll = "ls -al";
      la = "ls -A";
    };

    initContent = ''
      bindkey '^[[A' fzf-history-widget
      bindkey '^[[B' fzf-history-widget

      # setopt HIST_IGNORE_DUPS
      # setopt SHARE_HISTORY
      # setopt AUTO_CD
    '';
  };
  programs.starship = {
    enable = true;
  };
  programs.fzf = {
    enable = true;
  };
}
