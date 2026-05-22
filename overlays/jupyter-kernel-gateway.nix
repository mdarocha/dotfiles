{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
  jupyter-client,
  jupyter-core,
  jupyter-server,
  requests,
  tornado,
  traitlets,
}:

buildPythonPackage rec {
  pname = "jupyter_kernel_gateway";
  version = "3.0.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-kAaQxMDnloZzVUaNaF9/oc88d3XQjoccFX931l+9bX8=";
  };

  build-system = [ hatchling ];

  dependencies = [
    jupyter-client
    jupyter-core
    jupyter-server
    requests
    tornado
    traitlets
  ];

  # tests require network access and additional test dependencies
  doCheck = false;

  meta = {
    description = "A web server for spawning and communicating with Jupyter kernels";
    homepage = "https://github.com/jupyter/kernel_gateway";
    license = lib.licenses.bsd3;
    maintainers = [ ];
  };
}
