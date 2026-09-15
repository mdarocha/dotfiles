{ pkgs }:

let
  # Even with /dev/dri bound in (see allowGpu), ANGLE falls back to
  # SwiftShader unless it can also load a userspace GPU driver. The host
  # isn't NixOS, so there's no /run/opengl-driver to bind in — point the
  # loaders at nixpkgs' own Mesa build instead, which only needs /dev/dri
  # ioctls to work and doesn't have to match the host's Mesa version.
  mesaDriverEnv = ''
    export LIBGL_DRIVERS_PATH="${pkgs.mesa}/lib/dri"
    export __EGL_VENDOR_LIBRARY_FILENAMES="${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
    export VK_ICD_FILENAMES="${pkgs.mesa}/share/vulkan/icd.d/intel_icd.x86_64.json"
    # Mesa's GBM loader (buffer allocation for EGL/Wayland surfaces) has its
    # own separate search path from LIBGL_DRIVERS_PATH; without it ANGLE's
    # EGL init fails with "MESA-LOADER: failed to open dri: .../gbm/dri_gbm.so".
    export GBM_BACKENDS_PATH="${pkgs.mesa}/lib/gbm"
  '';
in
# Imports the sandbox proxy CA into Chromium's NSS cert store before launch.
# The proxy is a TLS-intercepting MITM whose CA is trusted by Node/curl via
# NODE_EXTRA_CA_CERTS / SSL_CERT_FILE, but Chromium uses its own NSS database
# (~/.pki/nssdb) and ignores those vars. Importing the cert here keeps full
# certificate verification intact — only the proxy CA is trusted, not
# arbitrary certs. The sandbox $HOME is an ephemeral tmpfs, so the DB is
# recreated fresh each session with the correct per-session CA. No-ops
# gracefully when the cert file is absent (i.e. outside the sandbox, where no
# proxy is running).
#
# --no-sandbox: Chromium tries to create its own inner sandbox via a second
#   layer of user namespaces. That nested-namespace creation is blocked
#   inside bwrap's user namespace. The flag disables Chromium's sandbox;
#   security is still provided by the surrounding bwrap sandbox.
# --disable-dev-shm-usage: bwrap gives the sandbox a fresh /tmp tmpfs and a
#   minimal /dev, so /dev/shm may be absent or very small. This flag makes
#   Chromium write shared memory blobs to /tmp instead, avoiding crashes.
pkgs.writeShellScriptBin "chromium" ''
  if [ -f /tmp/sandbox-ca-cert.pem ]; then
    NSS_DB="$HOME/.pki/nssdb"
    if [ ! -d "$NSS_DB" ]; then
      mkdir -p "$NSS_DB"
      ${pkgs.nss.tools}/bin/certutil -d "sql:$NSS_DB" -N --empty-password 2>/dev/null
    fi
    ${pkgs.nss.tools}/bin/certutil -d "sql:$NSS_DB" -A \
      -n "sandbox-proxy-ca" -t "C,," \
      -i /tmp/sandbox-ca-cert.pem 2>/dev/null || true
  fi
  ${mesaDriverEnv}
  exec ${pkgs.chromium}/bin/chromium --no-sandbox --disable-dev-shm-usage "$@"
''
