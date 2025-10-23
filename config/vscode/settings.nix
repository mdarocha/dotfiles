{ ... }:

{
  mdarocha.vscode = {
    settings = {
      "terminal.integrated.defaultProfile.linux" = "zsh";
       "git.autofetch" = true;
    };
    extensions = [
      "bbenoist.nix"
    ];
  };
}