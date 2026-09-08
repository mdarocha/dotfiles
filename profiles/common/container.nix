{
  mdarocha.zsh.autoDirectenvAllow = true;
  programs.man.enable = false;

  home.sessionVariablesExtra = ''
    unset __ETC_PROFILE_NIX_SOURCED
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  '';
}
