{ inputs }:
_final: prev: {
  git-ai = prev.callPackage ./git-ai.nix { gitAiSrc = inputs.git-ai; };

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyFinal: _pyPrev: {
      jupyter_kernel_gateway = pyFinal.callPackage ./jupyter-kernel-gateway.nix { };
    })
  ];
}
