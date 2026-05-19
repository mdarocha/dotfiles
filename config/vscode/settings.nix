{ ... }:

{
  mdarocha.vscode = {
    settings = {
      "terminal.integrated.defaultProfile.linux" = "zsh";
      "git.autofetch" = true;
      "git.enableSmartCommit" = true;
      "git.confirmSync" = false;
      "github.copilot.nextEditSuggestions.enabled" = false;
      "github.copilot.chat.claudeAgent.allowDangerouslySkipPermissions" = true;
      "chat.tips.enabled" = false;
      "editor.fontFamily" = "Hack Nerd Font Mono";
      "terminal.integrated.minimumContrastRatio" = 1;
      "workbench.colorTheme" = "Solarized Dark";
    };
    extensions = [
      "bbenoist.nix"
      "vscodevim.vim"
    ];
  };
}
