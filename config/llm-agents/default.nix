{
  lib,
  ...
}:

{
  imports = [
    ./sandbox
    ./copilot-cli
    ./oh-my-pi
  ];

  options.mdarocha.llm-agents = {
    enable = lib.mkEnableOption "llm-agents";
  };
}
