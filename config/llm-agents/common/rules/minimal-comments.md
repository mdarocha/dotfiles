---
name: minimal-comments
description: "Review every code comment against the project policy"
condition:
  - "(?m)(?:^[ \\t]*|[ \\t]+)(?://|/\\*|<!--)[ \\t]*\\S"
  - "(?m)(?:^[ \\t]*|[ \\t]+)#(?!(!|\\[|include|define|ifn?def|endif|if|elif|else|error|warning|pragma|import|region|endregion|line|undef|version|extension))[ \\t]*\\S"
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

You added or changed a code comment. Re-read § Comments in your global instructions and apply it
to the comment prose in this edit. Preserve existing comments unless the change
makes them false or redundant.

Cut each comment to the shortest form that still reads clearly; one line by
default. Drop lead-ins, restated code, and padding.

Then load the `humanizer` skill and make another pass over that prose. Remove AI
writing tells without changing the technical meaning or deleting useful context.
Do this now, in the same turn.

