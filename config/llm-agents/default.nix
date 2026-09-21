{
  config,
  lib,
  ...
}:
{
  imports = [
    ./common
    ./copilot-cli
    ./oh-my-pi
    ./claude-code
    ./cursor-agent
  ];

  options.mdarocha.llm-agents.enabledAgents = lib.mkOption {
    type = lib.types.listOf (
      lib.types.enum [
        "claude"
        "copilot"
        "cursor"
        "omp"
      ]
    );
    default = [ ];
  };

  config.mdarocha.llm-agents = {
    claude-code.enable = lib.mkDefault (lib.elem "claude" config.mdarocha.llm-agents.enabledAgents);
    copilot-cli.enable = lib.mkDefault (lib.elem "copilot" config.mdarocha.llm-agents.enabledAgents);
    cursor-agent.enable = lib.mkDefault (lib.elem "cursor" config.mdarocha.llm-agents.enabledAgents);
    oh-my-pi.enable = lib.mkDefault (lib.elem "omp" config.mdarocha.llm-agents.enabledAgents);
  };
}
