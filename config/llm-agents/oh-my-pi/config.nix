{ ... }:
{
  theme = {
    dark = "dark-solarized";
    light = "light-solarized";
  };
  symbolPreset = "nerd";
  defaultThinkingLevel = "auto";
  hideThinkingBlock = true;
  steeringMode = "all";
  followUpMode = "all";
  treeFilterMode = "no-tools";
  contextPromotion.enabled = true;
  compaction.thresholdPercent = 80;
  task = {
    isolation = {
      mode = "rcopy";
      merge = "branch";
      commits = "ai";
    };
    eager = "preferred";
    showResolvedModelBadge = true;
  };
  providers = {
    webSearchOrder = [
      "exa"
      "anthropic"
      "perplexity"
    ];
    fetch = "native";
    codeSearch = "grep";
  };
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
  startup.checkUpdate = false;
  memory.backend = "mnemopi";
  tools = {
    artifactSpillThreshold = 10;
    artifactTailBytes = 2.5;
    artifactHeadBytes = 2.5;
  };
  github.enabled = true;
  advisor.syncBacklog = "5";
  features.unexpectedStopDetection = true;
  terminal.showProgress = true;
  tui.textSizing = true;
  mnemopi = {
    scoping = "per-project-tagged";
    polyphonicRecall = true;
    enhancedRecall = true;
    proactiveLinking = true;
  };
  security.enabled = true;
  dev.autoqa = false;
  clearOnShrink = false;
  edit.hashlineAutoDropPureInsertDuplicates = true;
  python.toolMode = "both";
  renderMermaid.enabled = true;
  calc.enabled = true;
}
