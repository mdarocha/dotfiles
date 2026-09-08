{
  imports = [
    ./common/generic-linux.nix
    ./common/container.nix
  ];

  mdarocha.vscode.enable = true;

  home = {
    username = "codespace";
    homeDirectory = "/home/codespace";
  };

  programs.git.enable = false;
}
