# Default oh-my-pi settings, mirroring the live ~/.omp/agent/config.yml minus
# keys that already equal omp's own built-in schema default (redundant - see
# `omp config list --json` with an empty $HOME to dump the schema defaults)
# and minus `modelRoles`, which changes often via the TUI/`/model` and
# shouldn't fight with Nix on every apply. Override any of this per-machine
# via `mdarocha.llm-agents.oh-my-pi.settings`.
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
  contextPromotion = {
    enabled = true;
  };
  compaction = {
    thresholdPercent = 80;
  };
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
      "gemini"
      "codex"
      "xai"
      "zai"
      "tinyfish"
      "jina"
      "kagi"
      "tavily"
      "firecrawl"
      "brave"
      "kimi"
      "parallel"
      "synthetic"
      "searxng"
      "startpage"
      "duckduckgo"
      "ecosia"
      "google"
      "mojeek"
      "public"
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
  startup = {
    checkUpdate = false;
  };
  stt = {
    modelName = "base.en";
  };
  memory = {
    backend = "mnemopi";
  };
  tools = {
    artifactSpillThreshold = 10;
    artifactTailBytes = 2.5;
    artifactHeadBytes = 2.5;
  };
  github = {
    enabled = true;
  };
  setupVersion = 1;
  advisor = {
    syncBacklog = "5";
  };
  features = {
    unexpectedStopDetection = true;
  };
  terminal = {
    showProgress = true;
  };
  tui = {
    textSizing = true;
  };
  mnemopi = {
    scoping = "per-project-tagged";
    polyphonicRecall = true;
    enhancedRecall = true;
    proactiveLinking = true;
  };
  security = {
    enabled = true;
  };
  dev = {
    autoqa = false;
  };
  clearOnShrink = false;
  edit = {
    hashlineAutoDropPureInsertDuplicates = true;
  };
  python = {
    toolMode = "both";
  };
  renderMermaid = {
    enabled = true;
  };
  calc = {
    enabled = true;
  };
}
