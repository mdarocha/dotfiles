{ ... }:
{
  modelRoles = {
    default = "anthropic/claude-sonnet-5";
    smol = "anthropic/claude-haiku-4-5";
    slow = "anthropic/claude-opus-4-8";
    commit = "github-copilot/gpt-5-mini:low";
    plan = "anthropic/claude-opus-4-8:high";
    task = "anthropic/claude-sonnet-5";
    advisor = "anthropic/claude-haiku-4-5:high";
    designer = "anthropic/claude-opus-4-8:medium";
    tiny = "github-copilot/gpt-5-mini:low";
  };

  theme = {
    dark = "dark-solarized";
    light = "light-solarized";
  };

  symbolPreset = "nerd";
  colorBlindMode = false;

  statusLine = {
    preset = "default";
    separator = "powerline-thin";
    showHookStatus = true;
    sessionAccent = true;
  };

  images = {
    autoResize = true;
    blockImages = false;
  };

  display.showTokenUsage = false;

  showHardwareCursor = true;
  clearOnShrink = false;
  defaultThinkingLevel = "auto";
  hideThinkingBlock = true;
  steeringMode = "all";
  followUpMode = "all";
  interruptMode = "immediate";
  doubleEscapeAction = "tree";
  treeFilterMode = "no-tools";

  contextPromotion.enabled = true;

  compaction = {
    strategy = "snapcompact";
    thresholdPercent = 80;
    thresholdTokens = -1;
    handoffSaveToDisk = false;
    remoteEnabled = true;
  };

  edit = {
    mode = "hashline";
    fuzzyMatch = true;
    hashlineAutoDropPureInsertDuplicates = true;
  };

  bashInterceptor.enabled = false;

  python = {
    toolMode = "both";
    kernelMode = "session";
  };

  browser.enabled = true;

  task = {
    isolation = {
      mode = "rcopy";
      merge = "branch";
      commits = "ai";
    };
    eager = "preferred";
    batch = true;
    showResolvedModelBadge = true;
  };

  providers = {
    codeSearch = "grep";
    kimiApiFormat = "auto";
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
    autoThinkingMaxEffort = "xhigh";
  };

  retry = {
    fallbackRevertPolicy = "cooldown-expiry";
    fallbackChains."anthropic/*" = [ "github-copilot/*" ];
    usageAwareFallback = true;
    usageReservePct = 5;
    usageReservePolicy = "auto";
  };

  autoResume = false;

  loop.mode = "prompt";

  autocompleteMaxVisible = 5;

  startup.checkUpdate = false;

  ask.timeout = 0;

  stt = {
    modelName = "base.en";
    enabled = false;
  };

  memory.backend = "mnemopi";

  read.defaultLimit = 300;

  tools = {
    artifactSpillThreshold = 10;
    artifactTailBytes = 2.5;
    artifactHeadBytes = 2.5;
    xdevDocs = "builtins";
  };

  todo.remindersMax = 3;

  renderMermaid.enabled = true;
  calc.enabled = true;

  github = {
    enabled = true;
    cache.enabled = true;
  };

  mcp = { };

  async.enabled = true;

  grep = {
    contextBefore = 1;
    contextAfter = 3;
  };

  setupVersion = 1;

  advisor = {
    enabled = false;
    syncBacklog = "5";
  };

  features.unexpectedStopDetection = true;

  shellMinimizer.sourceOutlineLevel = "default";

  terminal.showProgress = true;

  tui.textSizing = true;

  autolearn.enabled = false;

  mnemopi.scoping = "per-project-tagged";

  modelRoleStorage = "global";

  security.enabled = true;

  astGrep.enabled = false;

  dev.autoqa = false;
}
