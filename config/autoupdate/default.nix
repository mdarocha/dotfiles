{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption mkIf types optionalString;
  cfg = config.mdarocha.autoupdate;
in
{
  options.mdarocha.autoupdate = {
    enable = mkEnableOption "autoupdate";

    path = mkOption {
      type = types.str;
      default = "mdarocha/dotfiles";
      description = "GitHub repository to get updates from";
    };

    notify = mkOption {
      type = types.bool;
      default = true;
      description = "Notify about updates";
    };

    frequency = mkOption {
      type = types.str;
      default = "daily";
      description = "When to run the update process";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.dotfiles-autoupdate = {
      Unit = {
        Description = "Automatically apply the newest ${cfg.path} flake";
      };
      Service = {
        Type = "oneshot";
        ExecStart = builtins.toString (
          pkgs.writeShellScript "dotfiles-autoupdate" ''
            ${optionalString cfg.notify ''
                NOTIFICATION_ID=$(${pkgs.libnotify}/bin/notify-send \
                  -p \
                  -a 'mdarocha/dotfiles'\
                  -c device \
                  -i computer \
                  'Starting ${cfg.path} update...')
            ''}

            ${pkgs.nix}/bin/nix run github:${cfg.path}#apply

            ${optionalString cfg.notify ''
                ${pkgs.libnotify}/bin/notify-send \
                  -r "$NOTIFICATION_ID" \
                  -a 'mdarocha/dotfiles' \
                  -c device \
                  -i computer \
                  'Finished ${cfg.path} update'
            ''}
          ''
        );
      };
    };
  };
}
