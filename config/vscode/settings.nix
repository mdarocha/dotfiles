{ ... }:

{
  mdarocha.vscode = {
    settings = {
      "terminal.integrated.defaultProfile.linux" = "zsh";
      "git.autofetch" = true;
      "git.enableSmartCommit" = true;
    };
    extensions = [
      "bbenoist.nix"
    ];
  };
}