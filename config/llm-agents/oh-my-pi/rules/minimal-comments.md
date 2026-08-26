---
name: minimal-comments
description: "Re-check every comment being written against the project comment policy"
condition:
  - "(?m)^[ \\t]*(//|/\\*|\\*[ \\t]|<!--)"
  - "(?m)^[ \\t]*#(?!(!|\\[|include|define|ifn?def|endif|if|elif|else|error|warning|pragma|import|region|endregion|line|undef|version|extension))[ \\t]*\\S"
  - "(?m)^[ \\t]*(--|;+|%|\\(\\*|!)[ \\t]+\\S"
  - "(?m)^[ \\t]*'[ \\t]+\\S"
scope: ["tool:edit", "tool:write", "tool:ast_edit"]
interruptMode: never
globs:
  - "*.{c,h,cc,cpp,cxx,hpp,cs,java,kt,kts,scala,swift,go,rs,zig}"
  - "*.{ts,tsx,js,jsx,mjs,cjs,vue,svelte,php,dart,py,rb,lua,pl,pm,r,jl}"
  - "*.{sh,bash,zsh,fish,ps1,nix,tf,proto,gradle,sql,hs,elm,ex,exs,erl}"
  - "*.{clj,cljs,el,lisp,scm,ml,mli,fs,fsx,css,scss,less,mk,cmake}"
  - "*.{html,xml,yaml,yml,toml,ini}"
  - "*.{vb,vbs,bas,pas,dpr,pp,f90,f95,f03,f08,ada,adb,ads,asm,d,mm,csh,tcsh,groovy,hcl,graphql,gql}"
  - "{Makefile,Dockerfile,*.Dockerfile}"
---

You just wrote a comment. The default is no comment, so deleting it is the expected
outcome — keep it only by naming which exception it falls under:

1. a *why* that is invisible locally (a constraint, a spec requirement, a business rule),
2. a subtle edge case a reader would not predict,
3. a workaround, with the issue linked,
4. doc-comment contract on a public surface: behavior, invariants, units, errors.

If you cannot name one, delete it now, in this same edit — not "later". A comment that
restates the code, labels structure, announces a phase, narrates the block below,
records the edit you just made, or sits above a self-evident line is deleted on sight.

Two further checks that override the list above:

- **Density.** Match the file's existing comment level; never raise it. If the
  surrounding code has no comments, yours needs a stronger reason than usual.
- **Durability.** It must stay true on any machine and after the next refactor.
  Never mention this session, host, sandbox, or what the code used to be.

Full policy: `AGENTS.md` § Comments.
