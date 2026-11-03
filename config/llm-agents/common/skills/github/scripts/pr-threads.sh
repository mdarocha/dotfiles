#!/usr/bin/env bash
# shellcheck disable=SC2016 # GraphQL variables must stay unexpanded in single quotes.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  pr-threads.sh list <pr> [-R owner/repo] [--all]
  pr-threads.sh reply <thread-id> <body> [-R owner/repo]
  pr-threads.sh resolve <thread-id>... [-R owner/repo]

list     unresolved review threads with their full comments, plus non-empty
         review summaries; --all includes resolved and outdated threads
reply    post a reply in an existing review thread
resolve  mark review threads resolved
EOF
}

GRAPHQL_PAGE=100

threads_query='
query($owner:String!, $repo:String!, $pr:Int!, $cursor:String) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$pr) {
      reviewThreads(first:100, after:$cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id isResolved isOutdated path line originalLine
          comments(first:100) { totalCount nodes { author { login } body url } }
        }
      }
      reviews(first:100) {
        totalCount
        nodes { author { login } state body url }
      }
    }
  }
}'

reply_mutation='
mutation($thread:ID!, $body:String!) {
  addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$thread, body:$body}) {
    comment { url }
  }
}'

resolve_mutation='
mutation($id:ID!) {
  resolveReviewThread(input:{threadId:$id}) { thread { id isResolved } }
}'

repo=""
all=0
args=()
while (($#)); do
  case $1 in
    -R | --repo)
      repo=$2
      shift 2
      ;;
    --all)
      all=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

repo_slug() {
  if [[ -n $repo ]]; then
    printf '%s\n' "$repo"
  else
    gh repo view --json nameWithOwner --jq .nameWithOwner
  fi
}

list() {
  local pr=${args[1]:?PR number required}
  local slug owner name cursor=null page
  slug=$(repo_slug)
  owner=${slug%%/*}
  name=${slug#*/}
  local threads=()
  while :; do
    page=$(gh api graphql -f query="$threads_query" -f owner="$owner" -f repo="$name" \
      -F pr="$pr" -F cursor="$cursor")
    threads+=("$(jq -c '.data.repository.pullRequest' <<<"$page")")
    [[ $(jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage' <<<"$page") == true ]] || break
    cursor=$(jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor' <<<"$page")
  done

  printf '%s\n' "${threads[@]}" | jq -rs --argjson all "$all" --argjson page "$GRAPHQL_PAGE" '
    (.[0].reviews.nodes[] | select(.body != "")
      | "== review @\(.author.login // "ghost") \(.state) \(.url)",
        (.body | split("\n")[] | "  | " + .)),
    (.[].reviewThreads.nodes[]
      | select($all == 1 or (.isResolved == false and .isOutdated == false))
      | "== thread \(.id) \(if .isResolved then "[resolved]" else "" end)\(if .isOutdated then "[outdated]" else "" end) \(.path // "-"):\(.line // .originalLine // "-")",
        (.comments.nodes[] | "  @\(.author.login // "ghost") \(.url)", (.body | split("\n")[] | "  | " + .)),
        (if .comments.totalCount > $page then "  (\(.comments.totalCount) comments; only the first \($page) shown)" else empty end))'
}

reply() {
  local thread=${args[1]:?thread ID required} body=${args[2]:?reply body required}
  gh api graphql -f query="$reply_mutation" -f thread="$thread" -f body="$body" \
    --jq '.data.addPullRequestReviewThreadReply.comment.url'
}

resolve() {
  local id
  for id in "${args[@]:1}"; do
    gh api graphql -f query="$resolve_mutation" -f id="$id" \
      --jq '"\(.data.resolveReviewThread.thread.id) resolved=\(.data.resolveReviewThread.thread.isResolved)"'
  done
}

case ${args[0]:-} in
  list) list ;;
  reply) reply ;;
  resolve) resolve ;;
  *)
    usage >&2
    exit 64
    ;;
esac
