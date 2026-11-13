## Copilot code review

Request a review with a chosen effort level through the [dedicated endpoint](https://docs.github.com/en/rest/pulls/copilot-code-review#request-a-copilot-code-review-for-a-pull-request):

```bash
gh api -X POST repos/{owner}/{repo}/pulls/123/copilot-code-review -f review_effort=lite
```

`review_effort` is `lite` or `balanced`, plus `max` or `auto` where enabled. Omit it to use the inherited level. Responses:

- `201`: requested. The same call re-requests once the previous Copilot review has finished.
- `409`: a Copilot review is already pending on the PR.
- `422` with `failure_reason` `INVALID_REVIEW_EFFORT`: the level is unavailable for this repository and actor; `message` lists the available ones. Other `failure_reason` values mean the actor or repository is ineligible or out of quota.

GraphQL equivalent: `requestCopilotCodeReview(input: {pullRequestId: $id, reviewEffort: LITE})`, with values from `CopilotCodeReviewEffort`.

`gh pr edit 123 --add-reviewer "@copilot"`, REST `requested_reviewers`, and GraphQL `requestReviews` take no effort level. The reviewer bot login is `copilot-pull-request-reviewer[bot]`; GraphQL `requestReviewsByLogin` takes it as `botLogins`.

Copilot uses the first effort that applies: the one chosen in the request, the one already used on the PR, the requester's personal setting, the repository setting, the organization setting (or the owner's setting on a user-owned repository), then Balanced. The `Review effort:` line in the review body shows what actually ran.
