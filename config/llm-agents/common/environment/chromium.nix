{ pkgs }:

# Without /run/opengl-driver (non-NixOS hosts such as WSL), ANGLE falls back
# to SwiftShader. Point the loaders at nixpkgs' Mesa, which only needs
# /dev/dri ioctls and doesn't have to match the host's Mesa version.
pkgs.writeShellScriptBin "chromium" ''
  export LIBGL_DRIVERS_PATH="${pkgs.mesa}/lib/dri"
  export __EGL_VENDOR_LIBRARY_FILENAMES="${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
  export VK_ICD_FILENAMES="${pkgs.mesa}/share/vulkan/icd.d/intel_icd.x86_64.json"
  # Mesa's GBM loader (buffer allocation for EGL/Wayland surfaces) has its
  # own separate search path from LIBGL_DRIVERS_PATH; without it ANGLE's
  # EGL init fails with "MESA-LOADER: failed to open dri: .../gbm/dri_gbm.so".
  export GBM_BACKENDS_PATH="${pkgs.mesa}/lib/gbm"
  exec ${pkgs.chromium}/bin/chromium "$@"
''
