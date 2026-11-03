---
name: browser-gpu
description: Confirm real GPU acceleration in the browser for WebGL rendering, GPU compute, or in-browser ML, and what to do when Chromium runs headless.
---

# Browser GPU acceleration

Some tasks (e.g. WebGL rendering, in-browser ML) require GPU acceleration in the browser; they are too slow without it.

Confirm the actual GPU backend via `chrome://gpu`'s "Graphics Feature Status" and `GPU0` fields, not `WEBGL_debug_renderer_info` or `navigator.userAgent`. The browser tool spoofs those for fingerprinting resistance regardless of the real backend.

GPU availability depends on whether (1) `/dev/dri` is currently available (it can be missing on a machine without a GPU), and (2) the browser is running in headless mode.

If Chromium runs headless but the task genuinely needs GPU-backed rendering (e.g. WebGL correctness, GPU compute), headless mode cannot provide it. Ask the user to switch the browser tool to visible (non-headless) mode and relaunch it.
