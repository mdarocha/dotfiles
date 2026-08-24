{ ... }:
{
  theme = {
    dark = "dark-solarized";
    light = "light-solarized";
  };
  symbolPreset = "nerd";
  terminal.showProgress = true;
  tui.textSizing = true;
  tui.renderMermaid = true;
  task.showResolvedModelBadge = true;

  advisor.syncBacklog = "5";
  defaultThinkingLevel = "auto";
  hideThinkingBlock = true;
  retry = {
    fallbackChains = {
      "anthropic/*" = [
        "github-copilot/*"
      ];
    };
    usageAwareFallback = true;
    usageReservePct = 5;
    usageReservePolicy = "auto";
  };

  steeringMode = "all";
  followUpMode = "all";
  treeFilterMode = "no-tools";
  startup.checkUpdate = false;
  features.unexpectedStopDetection = true;

  contextPromotion.enabled = true;
  compaction = {
    thresholdPercent = 80;
    methodOrder = [
      "snapcompact"
      "remote"
      "soft"
    ];
  };

  memory.backend = "mnemopi";
  mnemopi = {
    scoping = "per-project-tagged";
    polyphonicRecall = true;
    enhancedRecall = true;
    proactiveLinking = true;
  };

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

  task = {
    isolation = {
      mode = "rcopy";
      merge = "branch";
      commits = "ai";
    };
    eager = "preferred";
  };

  providers = {
    webSearchOrder = [
      "exa"
      "anthropic"
      "perplexity"
    ];
    fetch = "native";
  };

  composer.shape = "box";

  bash.direnv = "auto";

  share.store = "gist";
}
