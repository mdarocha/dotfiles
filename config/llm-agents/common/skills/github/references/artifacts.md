## Issue artifacts

`gh issue artifact` (preview, may change) attaches Markdown documents, HTML documents, and links to an issue, for plans, research, root-cause write-ups, or interactive diagrams. GitHub shows them alongside the issue, and HTML documents get a rendered preview with a source toggle. Issues only: pull requests and GitHub Enterprise Server are refused. These are unrelated to Actions artifacts (`gh run download`).

```bash
gh issue artifact create 142 'docs/plan.md#Sign-in plan' diagram.html https://example.com/thread
gh issue artifact create 142 plan.md --attach ./flow.png   # plan.md references ./flow.png
gh issue artifact list 142 --json number,name,type
gh issue artifact view 142 2 --json body --jq .body
gh issue artifact edit 142 2 --body-file plan.md           # saves a new version
gh issue artifact download 142 --dir artifacts
```

Each artifact has a number on its issue; commands take that number or the artifact URL (`.../issues/142/artifacts/2`), because names aren't unique. `create` makes one artifact per argument: `.md` and other text files become documents, `.html`/`.htm` become HTML documents, and URLs become links. Use `--body` or `--body-file -` with `--name` for a single document from text, and `--type embedded_html` to make that an HTML document. `--attach` works only on Markdown documents. `edit` keeps the type, records history (`view --version N`, `edit --restore-version N`), and `delete` is permanent and needs `--yes` when `gh` can't prompt. When `create` exits 1 after partial success, its piped output has a status column per artifact: retry only the `failed` lines.
