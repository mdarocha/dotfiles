{ domainList }:

builtins.replaceStrings [ "@domains@" ] [ domainList ] (builtins.readFile ./instructions/sandboxed.md)
