{ lib }:

let
  # Outbound domains the proxy allows for non-GET/HEAD methods, grouped for
  # display in agent instructions. Matching is by suffix, so 'foo.com' also
  # covers any *.foo.com subdomain.
  groups = {
    "Anthropic" = [
      "anthropic.com"
      "claude.ai"
      "claudeusercontent.com"
    ];
    "Azure DevOps" = [
      "dev.azure.com"
      "visualstudio.com"
      "vsassets.io"
      "login.microsoftonline.com"
      "blob.core.windows.net"
    ];
    "Contentful" = [
      "contentful.com"
      "ctfassets.net"
    ];
    "Documentation" = {
      "docs.github.com" = [
        "GET"
        "HEAD"
      ];
      "developers.google.com" = [
        "GET"
        "HEAD"
      ];
      "learn.microsoft.com" = [
        "GET"
        "HEAD"
      ];
      "mdn.mozilla.net" = [
        "GET"
        "HEAD"
      ];
    };
    "Figma" = [ "figma.com" ];
    "Google Antigravity (inference)" = {
      "cloudcode-pa.googleapis.com" = [
        "GET"
        "POST"
      ];
      "daily-cloudcode-pa.googleapis.com" = [
        "GET"
        "POST"
      ];
      "oauth2.googleapis.com" = [ "POST" ];
    };
    "OpenAI (inference)" = {
      "chatgpt.com" = [
        "GET"
        "POST"
      ];
    };
    "GitHub" = [
      "github.com"
      "githubusercontent.com"
    ];
    "GitHub Copilot" = [ "githubcopilot.com" ];
    "MCP tools" = [
      "mcp.grep.app"
      "mcp.context7.com"
      "mcp.exa.ai"
      "websetsmcp.exa.ai"
      "api.exa.ai"
    ];
    "Personal (mdarocha.pl)" = [
      "mdarocha.pl"
    ];
    "Model metadata" = {
      "models.dev" = [
        "GET"
        "HEAD"
      ];
    };
    "Nix" = [
      "nixos.org"
      "numtide.com"
      "cachix.org"
      "determinate.systems"
      "devenv.sh"
    ];
    "NuGet" = [ "api.nuget.org" ];
    "OMP" = [ "omp.sh" ];
    "OpenRouter" = [ "openrouter.ai" ];
    "npm" = [
      "npmjs.org"
      "npmjs.com"
      "yarnpkg.com"
      "fontawesome.com"
    ];
    "Python" = [
      "pypi.org"
      "python.org"
      "pythonhosted.org"
    ];
    "Rust" = [ "crates.io" ];
    "YouTube" = [
      "youtube.com"
      "googlevideo.com"
      "ytimg.com"
    ];
  };

  # A group is either a plain list of domains (all methods allowed) or an
  # attrset mapping each domain to "*" or a list of allowed HTTP methods.
  normalize =
    value:
    if builtins.isList value then
      builtins.listToAttrs (
        map (d: {
          name = d;
          value = "*";
        }) value
      )
    else
      value;

  render =
    value:
    if builtins.isList value then
      lib.concatMapStringsSep ", " (d: "\`${d}\`") value
    else
      lib.concatStringsSep ", " (
        lib.mapAttrsToList (
          domain: methods:
          if methods == "*" then
            "\`${domain}\`"
          else
            "\`${domain}\` (${lib.concatStringsSep ", " methods} only)"
        ) value
      );
in
{
  allowed = builtins.foldl' (acc: v: acc // normalize v) {
    "*" = [
      "GET"
      "HEAD"
    ];
  } (lib.attrValues groups);

  markdownList = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "- ${name}: ${render value}") groups
  );
}
