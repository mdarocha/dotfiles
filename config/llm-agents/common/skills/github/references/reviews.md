## Copilot code review

```bash
gh pr edit 123 --add-reviewer "@copilot"
```

The reviewer bot login is `copilot-pull-request-reviewer[bot]`; GraphQL `requestReviewsByLogin` takes it as `botLogins`. Review effort (Lite or Balanced) has no per-request parameter in the REST API, GraphQL schema, or `gh` as of `gh` 2.103.3, so don't guess a field such as `effort_level`. Without one, the effort comes from the requester's settings, so API-triggered reviews use the token owner's personal setting. The `Review effort:` line in the review body shows what actually ran. Recheck `gh pr edit --help` and cli/cli#14188 before claiming otherwise.
