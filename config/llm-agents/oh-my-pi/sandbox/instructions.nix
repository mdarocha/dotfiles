{
  lib,
  domainList,
}:

let
  render =
    file: vars:
    builtins.replaceStrings (map (name: "@${name}@") (lib.attrNames vars)) (lib.attrValues vars) (
      builtins.readFile file
    );
in
{
  sandboxed = render ./instructions/sandboxed.md { domains = domainList; };

  host = builtins.readFile ./instructions/host.md;
}
