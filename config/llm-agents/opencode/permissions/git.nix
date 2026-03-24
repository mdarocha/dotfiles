{ config, lib, ... }:

{
  config = lib.mkIf config.mdarocha.llm-agents.enable {
    programs.opencode.settings.permission.bash = {
      # ask before sending data to remotes
      "git push" = "ask";
      "git push *" = "ask";
      "git remote add *" = "ask";
      "git remote remove *" = "ask";
      "git remote rename *" = "ask";
      "git remote set-url *" = "ask";
    };
  };
}
