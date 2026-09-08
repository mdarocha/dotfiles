_final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyFinal: _pyPrev: {
      jupyter_kernel_gateway = pyFinal.callPackage ../packages/jupyter-kernel-gateway.nix { };
    })
  ];
}
