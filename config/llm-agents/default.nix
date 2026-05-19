{
  lib,
  ...
}:

{
  imports = [
    ./sandbox
    ./common
    ./copilot-cli
    ./oh-my-pi
  ];

  options.mdarocha.llm-agents = {
    enable = lib.mkEnableOption "llm-agents";
  };
}
