{ pkgs, self }:
let
  installerSrc = pkgs.lib.fileset.toSource {
    root = ../.;
    fileset = pkgs.lib.fileset.unions [
      ../install.sh
      ../scripts/lib.sh
    ];
  };

  activation =
    (self.homeConfigurations.nixos.extendModules {
      modules = [ { mdarocha.llm-agents.oh-my-pi.settings.providers.tinyModel = null; } ];
    }).activationPackage;
in
pkgs.testers.runNixOSTest {
  name = "nixos-activation";

  requiredFeatures.kvm = false;

  nodes.machine =
    { pkgs, ... }:
    {
      users.users.marek = {
        isNormalUser = true;
        uid = 1000;
        home = "/home/marek";
        shell = pkgs.bash;
      };

      virtualisation.writableStore = true;
      services.dbus.enable = true;
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          "marek"
        ];
      };
      virtualisation.additionalPaths = [ activation installerSrc ];
    };

  testScript = ''
    activation = "${activation}"
    installer_src = "${installerSrc}"

    machine.wait_for_unit("multi-user.target")
    machine.succeed("loginctl enable-linger marek")
    machine.succeed("systemctl start user@1000.service")
    machine.wait_for_unit("user@1000.service")
    machine.wait_for_file("/run/user/1000/bus")

    activation_env = "XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus HOME_MANAGER_BACKUP_EXT=backup"

    machine.succeed("install -d -m 700 -o marek -g users /home/marek/.config/zed")
    machine.succeed(
        "echo '{\"vim_mode\":false,\"local_only\":17}' > /home/marek/.config/zed/settings.json"
    )
    machine.succeed("chown marek:users /home/marek/.config/zed/settings.json")
    machine.succeed("install -d -m 700 -o marek -g users /home/marek/.omp/agent")
    machine.succeed("echo 'local_only: 17' > /home/marek/.omp/agent/config.yml")
    machine.succeed("chown marek:users /home/marek/.omp/agent/config.yml")
    machine.succeed("install -d -m 700 -o marek -g users /home/marek/.local/state/home-manager/gcroots")
    machine.succeed("chown -R marek:users /home/marek/.config /home/marek/.local")
    machine.succeed("install -d -m 700 -o marek -g users /home/marek/.local/state/nix/profiles")

    def activate():
        machine.succeed(
            f"su - marek -c '{activation_env} bash -x {activation}/activate > /tmp/activation.log 2>&1; echo $? > /tmp/activation.status'"
        )
        status = machine.succeed("cat /tmp/activation.status").strip()
        if status != "0":
            log = machine.succeed("cat /tmp/activation.log")
            raise AssertionError(f"activation exited {status}:\n{log}")
    activate()

    settings = machine.succeed("cat /home/marek/.config/zed/settings.json")
    assert '"vim_mode": true' in settings, settings
    assert '"local_only": 17' in settings, settings

    omp_config = machine.succeed("cat /home/marek/.omp/agent/config.yml")
    assert "local_only: 17" in omp_config, omp_config

    activate()

    settings_again = machine.succeed("cat /home/marek/.config/zed/settings.json")
    assert settings_again == settings, settings_again
    machine.succeed("test -f /home/marek/.config/zed/settings.json.backup")

    machine.succeed("su - marek -c 'git --version'")
    machine.succeed("su - marek -c 'zsh --version'")
    machine.succeed("su - marek -c 'omp-nosandbox --version'")
    machine.succeed("su - marek -c 'copilot-nosandbox --version'")
    machine.succeed("su - marek -c '/home/marek/.omp/agent/tools/yt-dlp --version'")

    machine.fail("test -e /nix/var/nix/profiles/default")

    forbidden_script = "#!/bin/sh\necho \"forbidden: $0 $*\" >> /tmp/fixture-events/forbidden.log\nexit 1\n"
    machine.succeed("mkdir -p /tmp/fixture-events /tmp/forbidden-bin")
    for forbidden_cmd in ["curl", "sudo", "chsh"]:
        machine.succeed(
            f"cat > /tmp/forbidden-bin/{forbidden_cmd} << 'SH'\n{forbidden_script}SH"
        )
        machine.succeed(f"chmod +x /tmp/forbidden-bin/{forbidden_cmd}")

    success_nix = "#!/bin/sh\necho \"$@\" >> /tmp/fixture-events/nix-calls.log\nexit 0\n"
    machine.succeed("mkdir -p /tmp/success-bin")
    machine.succeed(f"cat > /tmp/success-bin/nix << 'SH'\n{success_nix}SH")
    machine.succeed("chmod +x /tmp/success-bin/nix")

    machine.succeed(
        f"env -i PATH=/tmp/success-bin:/tmp/forbidden-bin:/run/current-system/sw/bin USER=marek HOME=/home/marek "
        f"bash {installer_src}/install.sh"
    )
    machine.succeed("test ! -e /tmp/fixture-events/forbidden.log")
    calls = machine.succeed("cat /tmp/fixture-events/nix-calls.log")
    assert calls.strip() == "run --accept-flake-config .#apply", calls

    fail_nix = "#!/bin/sh\necho \"$@\" >> /tmp/fixture-events/nix-calls-fail.log\nexit 23\n"
    machine.succeed("mkdir -p /tmp/fail-bin")
    machine.succeed(f"cat > /tmp/fail-bin/nix << 'SH'\n{fail_nix}SH")
    machine.succeed("chmod +x /tmp/fail-bin/nix")

    status, _ = machine.execute(
        f"env -i PATH=/tmp/fail-bin:/tmp/forbidden-bin:/run/current-system/sw/bin USER=marek HOME=/home/marek "
        f"bash {installer_src}/install.sh"
    )
    assert status == 23, status
    machine.succeed("test ! -e /tmp/fixture-events/forbidden.log")
    fail_calls = machine.succeed("cat /tmp/fixture-events/nix-calls-fail.log")
    assert len(fail_calls.strip().splitlines()) == 3, fail_calls
  '';
}
