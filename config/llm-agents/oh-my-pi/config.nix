{ ... }:
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
    memory = "local/qwen3-1.7b:low";
    web = "web/exa";
  };
  retry = {
    fallbackChains = {
      "anthropic/claude-sonnet-5" = [ "openai-codex/gpt-5.6-terra" ];
      "openai-codex/gpt-5.6-luna" = [ "anthropic/claude-haiku-4-5" ];
      "anthropic/claude-opus-5" = [ "openai-codex/gpt-5.6-sol" ];
      web = [
        "google/gemini-2.5-flash"
        "google-antigravity/gemini-2.5-flash"
        "openai-codex/gpt-5.6-luna"
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
  dev.autoqa = false;
  generate_image.enabled = true;
  ttsr = {
    repeatMode = "after-gap";
    repeatGap = 5;
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
  composer.shape = "box";

  # shell
  bash.direnv = "auto";

  # sharing
  share.store = "gist";

  # omp config audit decisions (see .omp/commands/omp-config-audit.md)
  # These comments are durable audit state; future runs must preserve them.
  # - modelRoles.{default,smol,slow,plan,task,commit,advisor,vision}: intentionally left unmanaged; skip in future audits.
  # - stt.modelName: intentionally left unmanaged; skip in future audits.

}
