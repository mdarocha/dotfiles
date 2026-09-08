{ pkgs }:
pkgs.runCommand "profile-selection" { nativeBuildInputs = [ pkgs.bash pkgs.coreutils ]; } ''
  source ${../scripts/lib.sh}
  base_path="$PATH"

  assert_profile() {
    expected="$1"
    os_release="$2"
    shift 2
    actual="$(env -i PATH="$base_path" "$@" bash -c 'source "$1"; detect_configuration "$2"' bash ${../scripts/lib.sh} "$os_release")"
    [ "$actual" = "$expected" ]
  }

  printf 'ID=nixos\n' > nixos
  printf "ID='nixos'\n" > quoted-single
  printf 'ID="nixos"\n' > quoted-double
  printf 'ID_LIKE=nixos\n' > like-only
  printf 'ID=steamos\n' > steamos
  printf 'ID=ubuntu\n' > ubuntu

  assert_profile nixos nixos
  assert_profile nixos quoted-single
  assert_profile nixos quoted-double
  assert_profile linux like-only
  assert_profile deck steamos CODESPACES=true WSL_DISTRO_NAME=Ubuntu CLAUDE_CODE_REMOTE=true
  assert_profile claude ubuntu CLAUDE_CODE_REMOTE=true
  assert_profile wsl ubuntu WSL_DISTRO_NAME=Ubuntu
  assert_profile codespace ubuntu CODESPACES=true

  mkdir -p profile/etc/profile.d profile/bin
  printf 'PATH="$PWD/profile/bin:$PATH"\nexport PATH\nprintf sourced > sourced\n' > profile/etc/profile.d/nix-daemon.sh
  printf '#!${pkgs.bash}/bin/bash\nexit 0\n' > profile/bin/nix
  chmod +x profile/bin/nix
  rm -f sourced
  [ "$(env -i PATH="$base_path" bash -c 'source "$1"; load_nix "$2" && command -v nix' bash ${../scripts/lib.sh} "$PWD/profile")" = "$PWD/profile/bin/nix" ]
  [ -f sourced ]

  mkdir -p fallback/bin
  printf '#!${pkgs.bash}/bin/bash\nexit 0\n' > fallback/bin/nix
  chmod +x fallback/bin/nix
  [ "$(env -i PATH="$base_path" bash -c 'source "$1"; load_nix "$2" && command -v nix' bash ${../scripts/lib.sh} "$PWD/fallback")" = "$PWD/fallback/bin/nix" ]

  ! env -i PATH="$base_path" bash -c 'source "$1"; load_nix "$2"' bash ${../scripts/lib.sh} "$PWD/missing"

  touch "$out"
''
