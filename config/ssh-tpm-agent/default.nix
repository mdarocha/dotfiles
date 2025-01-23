{
  config,
  lib,
  pkgs,
  ...
}:
# TODO upstream this
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    literalExpression
    ;

  cfg = config.services.ssh-tpm-agent;
in
{
  options = {
    services.ssh-tpm-agent = {
      enable = mkEnableOption "ssh-agent for TPMs";

      package = mkOption {
        type = types.package;
        default = pkgs.ssh-tpm-agent;
        defaultText = literalExpression "pkgs.ssh-tpm-agent";
        description = "The package to use for ssh-tpm-agent";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.ssh-tpm-agent" pkgs lib.platforms.linux)
    ];

    home.sessionVariablesExtra = ''
      if [ -z "$SSH_AUTH_SOCK" ]; then
        export SSH_AUTH_SOCK=$(${cfg.package}/bin/ssh-tpm-agent --print-socket)
      fi
    '';

    home.packages = [ cfg.package ];
  };
}
