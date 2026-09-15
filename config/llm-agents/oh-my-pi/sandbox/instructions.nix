{
  lib,
  packageNames,
  pythonPackageNames,
  domainList,
}:

let
  inlineNames = names: lib.concatMapStringsSep ", " (n: "\`${n}\`") names;

  render =
    file: vars:
    builtins.replaceStrings (map (name: "@${name}@") (lib.attrNames vars)) (lib.attrValues vars) (
      builtins.readFile file
    );
in
{
  toolset = render ./instructions/toolset.md {
    packages = inlineNames packageNames;
    pythonPackages = inlineNames pythonPackageNames;
  };

  sandboxed = render ./instructions/sandboxed.md {
    domains = domainList;
  };

  host = builtins.readFile ./instructions/host.md;
}
