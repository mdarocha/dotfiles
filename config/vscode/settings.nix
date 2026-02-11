{ ... }:

{
  mdarocha.vscode = {
    settings = {
      "terminal.integrated.defaultProfile.linux" = "zsh";
      "git.autofetch" = true;
      "git.enableSmartCommit" = true;
      "git.confirmSync" = false;
      "github.copilot.nextEditSuggestions.enabled" = false;
      "editor.fontFamily" = "Hack Nerd Font Mono";
    };
    extensions = [
      "bbenoist.nix"
      "vscodevim.vim"
    ];
  };
}
