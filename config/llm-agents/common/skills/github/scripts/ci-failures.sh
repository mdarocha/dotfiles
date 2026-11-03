#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ci-failures.sh [-R owner/repo] [-n lines] [--pr <number> | <run-id>]

Lists failed GitHub Actions jobs and steps, then each failed job's log with the
job/step/timestamp prefixes and ANSI colors removed: up to 30 earlier lines that
look like errors, then the last <lines> lines (default 60).
Without a target, uses the latest failed run on the current branch.
EOF
}

repo=()
lines=60
pr=""
run=""
while (($#)); do
  case $1 in
    -R | --repo)
      repo=(--repo "$2")
      shift 2
      ;;
    -n | --lines)
      lines=$2
      shift 2
      ;;
    --pr)
      pr=$2
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      run=$1
      shift
      ;;
  esac
done

if [[ -n $pr ]]; then
  # `gh pr checks` exits 8 while checks are pending; failed links are still printed.
  mapfile -t runs < <(
    gh pr checks "$pr" "${repo[@]}" --json bucket,link --jq '.[] | select(.bucket == "fail") | .link' |
      sed -n 's#.*/actions/runs/\([0-9]*\)/.*#\1#p' | sort -u
  )
elif [[ -n $run ]]; then
  runs=("$run")
else
  mapfile -t runs < <(
    gh run list "${repo[@]}" --branch "$(git branch --show-current)" --status failure --limit 1 \
      --json databaseId --jq '.[].databaseId'
  )
fi

if ((${#runs[@]} == 0)); then
  echo "No failed runs found." >&2
  exit 1
fi

for id in "${runs[@]}"; do
  gh run view "$id" "${repo[@]}" --json displayTitle,headBranch,url,jobs --jq '
    "# \(.displayTitle) (\(.headBranch)) \(.url)",
    (.jobs[] | select(.conclusion == "failure")
      | "failed job: \(.name); steps: \([.steps[] | select(.conclusion == "failure") | .name] | join(", "))")'

  # Each log line is "<job>\t<step>\t<timestamp> <text>".
  gh run view "$id" "${repo[@]}" --log-failed | LC_ALL=C awk -F'\t' -v tail_lines="$lines" '
    {
      job = $1
      sub(/^[^\t]*\t[^\t]*\t/, "")
      sub(/^\xef\xbb\xbf/, "")
      sub(/^[0-9-]+T[0-9:.]+Z ?/, "")
      gsub(/\x1b\[[0-9;]*[A-Za-z]/, "")
      if ($0 == "##[endgroup]") next
      if (!(job in count)) order[++jobs] = job
      log_line[job, ++count[job]] = $0
    }
    END {
      for (j = 1; j <= jobs; j++) {
        job = order[j]
        start = count[job] - tail_lines + 1
        if (start < 1) start = 1
        printf "\n== %s (%d lines)\n", job, count[job]
        shown = 0
        for (i = 1; i < start && shown < 30; i++) {
          line = tolower(log_line[job, i])
          if (line ~ /##\[error\]|error|fail|panic|exception|traceback/) {
            print i ": " log_line[job, i]
            shown++
          }
        }
        if (shown) print "-- last lines"
        for (i = start; i <= count[job]; i++) print log_line[job, i]
      }
    }'
done
