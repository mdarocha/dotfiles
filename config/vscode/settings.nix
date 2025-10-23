{ ... }:

{
  mdarocha.vscode = {
    settings = {
      "terminal.integrated.defaultProfile.linux" = "zsh";
      "git.autofetch" = true;
      "git.enableSmartCommit" = true;
      "git.confirmSync" = false;
    };
    extensions = [
      "bbenoist.nix"
    ];
  };
}