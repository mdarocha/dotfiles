{ ... }:

{
  mdarocha.vscode = {
    settings = {
      "terminal.integrated.defaultProfile.linux" = "zsh";
      "git.autofetch" = true;
      "git.enableSmartCommit" = true;
      "git.confirmSync" = false;
      "github.copilot.nextEditSuggestions.enabled" = false;
    };
    extensions = [
      "bbenoist.nix"
    ];
  };
}
