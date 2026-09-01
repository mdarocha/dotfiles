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
  task.showResolvedModelBadge = true;

  # model
  advisor.syncBacklog = "5";
  defaultThinkingLevel = "auto";
  hideThinkingBlock = true;
  retry = {
    fallbackChains = {
      "anthropic/claude-sonnet-5" = [
        "openai-codex/gpt-5.6-terra"
        "google-antigravity/claude-sonnet-4-6"
        "github-copilot/claude-sonnet-5"
      ];
      "openai-codex/gpt-5.6-luna" = [
        "anthropic/claude-haiku-4-5"
        "google-antigravity/gemini-3.7-flash"
        "github-copilot/gpt-5.6-luna"
      ];
      "anthropic/claude-opus-5" = [
        "openai-codex/gpt-5.6-sol"
        "github-copilot/claude-opus-5"
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
  startup.checkUpdate = false;
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
      mode = "rcopy";
      merge = "branch";
      commits = "ai";
    };
    eager = "preferred";
  };

  # providers
  providers = {
    webSearchOrder = [
      "exa"
      "anthropic"
      "perplexity"
    ];
    fetch = "native";
    tinyModel = "lfm2-350m";
    imageOrder = [
      "antigravity"
      "openai-codex"
    ];
  };

  # composer
  composer.shape = "box";

  # shell
  bash.direnv = "auto";

  # sharing
  share.store = "gist";
}
