#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ci-wait.sh [-R owner/repo] [--pr <number> | --sha <commit>] [options]

Waits until every check run and commit status on a commit finishes, printing
nothing while it waits. Then prints one line per check and, for failed Actions
runs, the ci-failures.sh excerpt. Default commit: the current branch's PR head,
else local HEAD.

Options:
  --timeout <s>   give up after this many seconds (default 1800)
  --interval <s>  seconds between polls (default 30)
  --grace <s>     how long to wait for the first check to appear (default 120)
  --no-logs       skip the failure log excerpt

Exit status: 0 all passed, 1 a check failed, 2 timed out, 3 no checks appeared.
EOF
}

repo=""
pr=""
sha=""
timeout=1800
interval=30
grace=120
logs=1
while (($#)); do
  case $1 in
    -R | --repo)
      repo=$2
      shift 2
      ;;
    --pr)
      pr=$2
      shift 2
      ;;
    --sha)
      sha=$2
      shift 2
      ;;
    --timeout)
      timeout=$2
      shift 2
      ;;
    --interval)
      interval=$2
      shift 2
      ;;
    --grace)
      grace=$2
      shift 2
      ;;
    --no-logs)
      logs=0
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 64
      ;;
  esac
done

repo_flag=()
if [[ -n $repo ]]; then
  repo_flag=(--repo "$repo")
else
  repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
fi

if [[ -z $sha && -n $pr ]]; then
  sha=$(gh pr view "$pr" "${repo_flag[@]}" --json headRefOid --jq .headRefOid)
elif [[ -z $sha ]]; then
  sha=$(gh pr view --json headRefOid --jq .headRefOid 2>/dev/null || git rev-parse HEAD)
fi

# One row per check: name, status, conclusion, details URL.
snapshot() {
  gh api --paginate "repos/$repo/commits/$sha/check-runs?per_page=100" \
    --jq '.check_runs[] | [.name, .status, (.conclusion // ""), (.details_url // "")] | @tsv'
  gh api "repos/$repo/commits/$sha/status" \
    --jq '.statuses[] | [.context, (if .state == "pending" then "pending" else "completed" end), .state, (.target_url // "")] | @tsv'
}

pending() {
  awk -F'\t' '$2 != "completed"' <<<"$1"
}

start=$SECONDS
settled=""
while :; do
  rows=$(snapshot)
  elapsed=$((SECONDS - start))

  if [[ -z $rows ]]; then
    if ((elapsed >= grace)); then
      echo "No checks reported for ${sha:0:7} in $repo after ${grace}s."
      exit 3
    fi
  elif [[ -z $(pending "$rows") ]]; then
    # Workflows can start after others finish, so require two settled polls with the same checks.
    if [[ $rows == "$settled" ]]; then
      break
    fi
    settled=$rows
  else
    settled=""
  fi

  if ((elapsed >= timeout)); then
    echo "Timed out after ${timeout}s on ${sha:0:7}. Still running:"
    pending "$rows" | cut -f1,2
    exit 2
  fi
  sleep "$interval"
done

failed=$(awk -F'\t' '$3 !~ /^(success|neutral|skipped)$/' <<<"$rows")

echo "Checks for ${sha:0:7} in $repo:"
{
  printf '%s\n' "$failed"
  awk -F'\t' '$3 ~ /^(success|neutral|skipped)$/' <<<"$rows"
} | awk -F'\t' 'NF { printf "%-16s %s\n", $3, $1 }'

if [[ -z $failed ]]; then
  exit 0
fi

awk -F'\t' '$4 !~ /\/actions\/runs\// { print "details: " $1 " " $4 }' <<<"$failed"
if ((logs)); then
  script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  sed -n 's#.*/actions/runs/\([0-9]*\).*#\1#p' <<<"$failed" | sort -u | while read -r run; do
    "$script_dir/ci-failures.sh" -R "$repo" "$run" || true
  done
fi
exit 1
