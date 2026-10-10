## Network log

This agent runs behind a local HTTP proxy that records which hosts each session
contacted. Logs are in `@dir@`:

- `network.log`: one `[session: <start> - <end>] <agent> <cwd>` block per session,
  listing hosts and request counts (CONNECT tunnels for HTTPS, requests for plain HTTP).
- `sessions.jsonl`: the same data as one JSON record per session.

It only observes: nothing is blocked, and clients that ignore `HTTP(S)_PROXY` are not logged.
