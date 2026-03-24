{ config, lib, ... }:

{
  config = lib.mkIf config.mdarocha.llm-agents.enable {
    programs.opencode.skills = {
      gh-cli = ./gh-cli;
      run-with-nix = ./run-with-nix;
    };
  };
}
