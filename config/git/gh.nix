{ lib, pkgs, ... }:
{
  programs.gh = {
    enable = lib.mkDefault true;
    extensions = [
      pkgs.gh-stack
      pkgs.gh-actions-lock
    ];
  };
}
