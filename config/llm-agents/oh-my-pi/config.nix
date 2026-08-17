# Grouped and ordered to match the `/settings` panel / `omp://settings.md`
# catalog, so a section here maps 1:1 onto a section there.
{ ... }:
{
  # Advisor
  advisor.syncBacklog = "5";

  # Thinking
  defaultThinkingLevel = "auto";
  hideThinkingBlock = true;

  # Retry and fallback
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

  # Tools and approvals
  tools = {
    artifactSpillThreshold = 10;
    artifactTailBytes = 2.5;
    artifactHeadBytes = 2.5;
  };
  calc.enabled = true;
  renderMermaid.enabled = true;
  security.enabled = true;

  # Shell, eval, and LSP
  python.toolMode = "both";

  # Files: editing and reading
  edit.hashlineAutoDropPureInsertDuplicates = true;

  # Context, compaction, and memory
  contextPromotion.enabled = true;
  compaction.thresholdPercent = 80;
  memory.backend = "mnemopi";
  mnemopi = {
    scoping = "per-project-tagged";
    polyphonicRecall = true;
    enhancedRecall = true;
    proactiveLinking = true;
  };

  # Appearance and terminal
  theme = {
    dark = "dark-solarized";
    light = "light-solarized";
  };
  symbolPreset = "nerd";
  terminal.showProgress = true;
  tui.textSizing = true;
  clearOnShrink = false;

  # Interaction
  steeringMode = "all";
  followUpMode = "all";
  treeFilterMode = "no-tools";

  # Providers and services
  providers = {
    webSearchOrder = [
      "exa"
      "anthropic"
      "perplexity"
    ];
    fetch = "native";
    codeSearch = "grep";
  };

  # Other groups (task.*, github.*, startup.*, features.*, dev.*)
  task = {
    isolation = {
      mode = "rcopy";
      merge = "branch";
      commits = "ai";
    };
    eager = "preferred";
    showResolvedModelBadge = true;
  };
  github.enabled = true;
  startup.checkUpdate = false;
  features.unexpectedStopDetection = true;
  dev.autoqa = false;
}
