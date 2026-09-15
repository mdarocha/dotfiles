{
  lib,
  ...
}:

{
  imports = [
    ./common
    ./copilot-cli
    ./oh-my-pi
    ./claude-code
  ];

  options.mdarocha.llm-agents = {
    enable = lib.mkEnableOption "llm-agents";
  };
}
