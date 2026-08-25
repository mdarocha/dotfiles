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
      "anthropic/*" = [
        "github-copilot/*"
      ];
      "google-antigravity/gemini-3.7-flash" = [
        "openai-codex/gpt-5.6-luna"
        "anthropic/claude-haiku-4-5"
      ];
      "anthropic/claude-sonnet-5" = [
        "google-antigravity/claude-sonnet-4-6"
        "openai-codex/gpt-5.6-terra"
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
  features.unexpectedStopDetection = true;

  # context
  contextPromotion.enabled = true;
  compaction = {
    thresholdPercent = 80;
    methodOrder = [
      "snapcompact"
      "remote"
      "soft"
    ];
  };

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
  };

  # composer
  composer.shape = "box";

  # shell
  bash.direnv = "auto";

  # sharing
  share.store = "gist";
}
