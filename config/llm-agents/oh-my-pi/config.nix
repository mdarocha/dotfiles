{ config, ... }:
{
  # appearance
  theme = {
    dark = "dark-solarized";
    light = "light-solarized";
  };
  symbolPreset = "nerd";
  terminal.showProgress = true;
  tui.textSizing = true;
  tui.renderMermaid = true;
  tui.vimMode = true;
  task.showResolvedModelBadge = true;

  # model
  advisor.syncBacklog = "5";
  defaultThinkingLevel = "auto";
  hideThinkingBlock = true;
  modelRoles = {
    tiny = "local/lfm2.5-350m:off";
    memory = "local/lfm2-1.2b:low";
    web = "web/exa";
  };
  retry = {
    fallbackChains = {
      "anthropic/claude-sonnet-5" = [ "openai-codex/gpt-6-sol" ];
      "openai-codex/gpt-6-luna" = [ "anthropic/claude-haiku-4-5" ];
      "anthropic/claude-opus-5-5" = [ "openai-codex/gpt-6-sol" ];
      web = [
        "google/gemini-2.5-flash"
        "google-antigravity/gemini-2.5-flash"
        "openai-codex/gpt-6-luna"
        "openai-codex/gpt-5.5"
      ];
      image = [
        "openai-codex/gpt-image-1"
        "openai/gpt-image-1"
        "openrouter/google/gemini-3-pro-image-preview"
        "google/gemini-3-pro-image-preview"
      ];
    };
    usageAwareFallback = true;
    usageReservePct = 5;
    usageReservePolicy = "auto";
  };

  # interaction
  steeringMode = "all";
  followUpMode = "all";
  treeFilterMode = "no-tools";
  doubleEscapeAction = "tree";
  startup.checkUpdate = false;
  marketplace.autoUpdate = "off";
  autocompleteMaxVisible = 5;
  features.unexpectedStopDetection = "smart";

  # context
  contextPromotion.enabled = true;
  compaction = {
    thresholdPercent = 80;
    thresholdTokens = -1;
    handoffSaveToDisk = false;
    methodOrder = [
      "snapcompact"
      "remote"
      "soft"
    ];
  };
  extendedContext = true;

  # memory
  memory.backend = "mnemopi";
  mnemopi = {
    scoping = "per-project-tagged";
    polyphonicRecall = true;
    enhancedRecall = true;
    proactiveLinking = true;
  };

  # tools
  tools = {
    artifactSpillThreshold = 10;
    artifactTailBytes = 2.5;
    artifactHeadBytes = 2.5;
  };
  security.enabled = true;
  github.enabled = true;
  generate_image.enabled = true;
  ttsr = {
    repeatMode = config.mdarocha.llm-agents.ruleRepeat.mode;
    repeatGap = config.mdarocha.llm-agents.ruleRepeat.gap;
  };

  # tasks
  task = {
    isolation = {
      enabled = false;
      merge = "branch";
      commits = "ai";
    };
    eager = "preferred";
    agentPrewalk.designer = "on";
  };
  isolation.backend = "auto";

  # providers
  providers = {
    fetch = "native";
  };
  codexResets.autoRedeem = "yes";

  # composer
  composer.shape = "claude";

  # shell
  bash.direnv = "auto";

  # sharing and omp.sh services
  share.store = "gist";
  # The stream server can't be self-hosted; loopback keeps `omp stream` off omp.sh.
  stream.serverUrl = "http://localhost";
  dev.autoqa = false;

  # omp config audit decisions (see .omp/commands/omp-config-audit.md)
  # These comments are durable audit state; future runs must preserve them.
  # - modelRoles.{default,smol,slow,plan,task,commit,advisor,vision}: intentionally left unmanaged; skip in future audits.
  # - stt.modelName: intentionally left unmanaged; skip in future audits.

}
