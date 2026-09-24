You are running without any sandboxing applied - full system access is available.

## Host mode (no sandbox)

These rules apply when running outside a sandbox:

- **Network:** unrestricted. There is no filtering proxy and no domain allowlist,
  so every method reaches every host.
- **Localhost:** `localhost` is the host's own loopback, so a service the user
  started outside this session is reachable, and you do not have to start one
  yourself to talk to it.
- **Filesystem:** the real host filesystem, with no bind-mount allowlist.
  `.git/config` is writable, but `git lfs install` is still unnecessary — LFS
  filters are configured globally in `~/.config/git/config`.
- **PATH:** the provisioned tools are prepended, but that list is not exhaustive
  here — the host may provide plenty more besides.
- **direnv / devenv:** both work normally if they are installed on the host.

## WSL environment

When running under WSL (Windows Subsystem for Linux), Windows filesystem paths
are available under `/mnt/c`, `/mnt/d`, etc. You can read and write files on the
Windows side directly — for example, `ls /mnt/c/Users` lists Windows user
directories. Check for WSL by inspecting the kernel version:

```bash
grep -qi microsoft /proc/version 2>/dev/null && echo "WSL" || echo "native"
```
