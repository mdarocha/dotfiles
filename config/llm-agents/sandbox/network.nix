{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.mdarocha.llm-agents.sandbox = {
    allowedDomainGroups = mkOption {
      type = types.attrsOf (types.either (types.listOf types.str) (types.attrsOf (types.either types.str (types.listOf types.str))));
      description = ''
        Allowed outbound domains, grouped for display in agent instructions.
        Each group value is either:
        - A list of domain suffixes (all HTTP methods allowed), or
        - An attrset mapping each domain suffix to "*" (all methods) or a list
          of allowed HTTP methods (e.g. ["GET" "HEAD"]).
        The proxy matches by suffix so 'foo.com' also covers any *.foo.com subdomain.
      '';
      default = {
        "Anthropic" = [ "anthropic.com" "claude.ai" "claudeusercontent.com" ];
        "Azure DevOps" = [ "dev.azure.com" "visualstudio.com" "vsassets.io" "login.microsoftonline.com" "blob.core.windows.net" ];
        "Contentful" = [ "contentful.com" "ctfassets.net" ];
        "Documentation" = {
          "docs.github.com" = [ "GET" "HEAD" ];
          "developers.google.com" = [ "GET" "HEAD" ];
          "learn.microsoft.com" = [ "GET" "HEAD" ];
          "mdn.mozilla.net" = [ "GET" "HEAD" ];
        };
        "Figma" = [ "figma.com" ];
        "Google Antigravity (inference)" = {
          "cloudcode-pa.googleapis.com" = [ "GET" "POST" ];
          "daily-cloudcode-pa.googleapis.com" = [ "GET" "POST" ];
          "oauth2.googleapis.com" = [ "POST" ];
        };
        "OpenAI (inference)" = { "chatgpt.com" = [ "GET" "POST" ]; };
        "GitHub" = [ "github.com" "githubusercontent.com" ];
        "GitHub Copilot" = [ "githubcopilot.com" ];
        "MCP tools" = [ "mcp.grep.app" "mcp.context7.com" "mcp.exa.ai" "websetsmcp.exa.ai" "api.exa.ai" ];
        "Personal (mdarocha.pl)" = [ "mdarocha.pl" ];
        "Model metadata" = { "models.dev" = [ "GET" "HEAD" ]; };
        "Nix" = [ "nixos.org" "numtide.com" "cachix.org" "determinate.systems" "devenv.sh" ];
        "NuGet" = [ "api.nuget.org" ];
        "OMP" = [ "omp.sh" ];
        "OpenRouter" = [ "openrouter.ai" ];
        "npm" = [ "npmjs.org" "npmjs.com" "yarnpkg.com" "fontawesome.com" ];
        "Python" = [ "pypi.org" "python.org" "pythonhosted.org" ];
        "Rust" = [ "crates.io" ];
        "YouTube" = [ "youtube.com" "googlevideo.com" "ytimg.com" ];
      };
    };

    allowGetAnywhere = mkOption {
      type = types.bool;
      default = true;
      description = "Allow GET and HEAD requests to any domain. Enables unrestricted web browsing and searching without listing every destination. When enabled, a wildcard entry for GET and HEAD is prepended to the proxy allowlist.";
    };
  };
}
