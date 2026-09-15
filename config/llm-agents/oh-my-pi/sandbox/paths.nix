{ lib }:

let
  rwDirs = [
    "$HOME/.omp"

    # Nix user config and profile state, so nix commands (registry, config,
    # nix-env) persist their state across sandbox runs.
    "$HOME/.config/nix"
    "$HOME/.local/state/nix"

    "$HOME/.npm"
    "$HOME/.bun/install/cache"
    "$HOME/.cache/nix"
    "$HOME/.cache/nix-index"
    "$HOME/.cache/direnv"
    "$HOME/.cargo"
    "$HOME/.rustup"

    # Private NuGet artifact feeds.
    "$HOME/.nuget"
    "$HOME/.dotnet"
    "$HOME/.local/share/MicrosoftCredentialProvider"
    "$HOME/.local/.IdentityService"
    "$HOME/.microsoft/usersecrets"
  ];

  rwFiles = [
    "$HOME/.npmrc"
    "$HOME/.bunfig.toml"
  ];

  # Git identity config is bound read-only (not a rwDir) so the agent can't
  # plant core.hooksPath / alias.* entries that would fire host-side code on
  # the next host `git` invocation — see the upstream README's "Git identity"
  # section.
  roDirs = [
    "$HOME/.config/direnv"
    "$HOME/.local/share/direnv"
    "$HOME/.config/git"
  ];

  roFiles = [ "$HOME/.config/gh/config.yml" ];

  quoted = paths: lib.concatMapStringsSep " " (p: ''"${p}"'') paths;
in
{
  inherit
    rwDirs
    rwFiles
    roDirs
    roFiles
    ;

  # agent-sandbox.nix hard-errors at launch if a declared rwDir / rwFile /
  # roDir / roFile is missing on the host, and upstream deliberately
  # removed creating them itself: silently creating agent-declared paths at
  # every launch risks masking typos as new state directories.
  # See https://github.com/archie-judd/agent-sandbox.nix/pull/72.
  ensureDirs = ''
    mkdir -p ${quoted (rwDirs ++ roDirs)}
    mkdir -p ${quoted (map builtins.dirOf (rwFiles ++ roFiles))}
    for f in ${quoted (rwFiles ++ roFiles)}; do
      [ -e "$f" ] || touch "$f" || true
    done
  '';
}
