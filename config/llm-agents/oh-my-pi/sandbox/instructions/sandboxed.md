You are running inside a sandbox.

## Toolset limits (sandbox only)

Inside the sandbox the provisioned list is **all** there is: no other binaries
are on PATH and none of the host's own tools leak in. Check that list before
reaching for a command, and pull anything missing using Nix.

## direnv and devenv (sandbox only)

`direnv` and `devenv` are **not** in the sandbox PATH. In most cases you do
**not need them** — the sandbox already provides the common development tools
listed above (git, node, cargo, python, etc.). Only reach for direnv/devenv
when the project requires project-specific tools or environment variables that
are not already on PATH.

If you do need them:
- **direnv:** `nix run nixpkgs#direnv -- allow . && eval "$(nix run nixpkgs#direnv -- export bash)"`
- **devenv:** `nix run github:cachix/devenv -- shell` or `nix develop`
- **nix develop:** If the project has a `flake.nix` with `devShells`, use
  `nix develop --command <cmd>` directly — `nix` is always available.

## Network restrictions (sandbox only)

Outbound network access is restricted by a filtering proxy. HTTP requests will
fail with connection errors for any disallowed domain or method.

Also note that the network proxy will allow ONLY http requests - this means any non-HTTP
network calls like SSH or custom protocols will always fail. If you need them, inform the user
that they need to disable the sandbox by running the `omp-nosandbox` binary.

All blocked requests will show up in `/tmp/sandbox-proxy.log`. You don't have access to this file while inside the sandbox.
If you suspect your issue is caused by sandbox blocking a network request, inform the user that they should check there.

Domains use suffix matching: `github.com` also covers `api.github.com`,
`raw.github.com`, and any other subdomain.

GET and HEAD requests are allowed to **any** domain — use these freely for web search and browsing.
All other methods are restricted to the domains below:

@domains@

## Localhost / loopback isolation (sandbox only)

The sandbox network namespace is isolated from the host. `localhost` (`127.0.0.1`)
inside the sandbox is the **sandbox's own loopback** — it does **not** reach services
running on the host machine.

Consequence: if a task requires a locally-running service (dev server, database,
etc.), **the agent must start it** via `bash` inside the current session.
Asking the user to start it on their machine and then connecting to it will not work.

## Windows filesystem paths (sandbox only)

Under WSL the Windows drives (`/mnt/c`, `/mnt/d`, …) are **not** reachable: the
sandbox binds only an explicit set of directories into its filesystem namespace.
If a task needs Windows-side files, run `omp-nosandbox` instead, or ask
the user to copy them into the Linux filesystem first.

## `.git/config` (sandbox only)

`.git/config` in a project checkout is **read-only** inside the sandbox — any
write to it, e.g. `git config --local ...`, fails with "Device or resource
busy" / "Read-only file system". This is not repo-specific; it applies to
every checkout.
