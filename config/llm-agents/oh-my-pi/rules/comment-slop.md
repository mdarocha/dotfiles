---
name: comment-slop
description: "Block the comment shapes that are never justified"
condition:
  # Phase/step headers: "// Step 1: validate"
  - "(?im)^[ \\t]*(?://|/\\*|#|--|;+|%|\\*|<!--|'|!)[ \\t]*(?:step|phase|part)[ \\t]*\\d+\\b"
  # Decorative separators: "// ============"
  - "(?m)^[ \\t]*(?://|/\\*|#|--|;+|%|\\*|<!--|'|!)[ \\t]*[-=*_~+#]{6,}[ \\t]*(?:\\*/|-->)?[ \\t]*$"
  # Edit history: "// changed from", "// now handles", "// no longer needed"
  - "(?im)^[ \\t]*(?://|/\\*|#|--|;+|%|\\*|<!--|'|!)[ \\t]*(?:changed from|used to be|previously[ ,]|now (?:handles|uses|returns|does|supports|works)|renamed (?:from|to)|no longer|was:|new:|added:|removed:|updated:|fixed:)"
  # Structural labels: "# imports", "// helpers"
  - "(?im)^[ \\t]*(?://|/\\*|#|--|;+|%|\\*|<!--|'|!)[ \\t]*(?:imports?|exports?|helpers?|constants?|globals?|utils?|setup|teardown|cleanup|initialization|main|config|interfaces?|props|state|handlers?|getters?|setters?|variables?|functions?|classes?|dependencies)[ \\t]*:?[ \\t]*(?:\\*/|-->)?[ \\t]*$"
  # Narration of the next line: "// Loop through the items"
  - "(?im)^[ \\t]*(?://|/\\*|#|--|;+|%|\\*|<!--|'|!)[ \\t]*(?:loop through|iterate over|initialize|increment|decrement|return the|call the|create (?:a|an|the) new|check if|set the|get the|add the|remove the|update the|delete the|assign the|declare|define the|import the|export the|instantiate|print the|log the|convert the|parse the|validate the|handle the|process the)\\b"
  # Doc restatement: "@param id - the id"
  - "(?im)^[ \\t]*(?://|/\\*+|#|\\*)?[ \\t]*[@\\\\](?:param|arg|argument)[ \\t]+\\S+[ \\t]*[-–—:]?[ \\t]*(?:the|a|an)[ \\t]+\\w+[ \\t]*(?:\\*/|-->)?[ \\t]*$"
  - "(?im)^[ \\t]*(?://|/\\*+|#|\\*)?[ \\t]*[@\\\\]returns?[ \\t]+(?:the|a|an)[ \\t]+\\w+[ \\t]*(?:\\*/|-->)?[ \\t]*$"
  # Assistant chatter left in code
  - "(?im)^[ \\t]*(?://|/\\*|#|--|;+|%|\\*|<!--|'|!)[ \\t]*(?:as requested|as you asked|for clarity|for readability|best practice|note that this is|this is a placeholder|for demonstration|unchanged)\\b"
scope: ["tool:edit", "tool:write", "tool:ast_edit"]
interruptMode: tool-only
globs:
  - "*.{c,h,cc,cpp,cxx,hpp,cs,java,kt,kts,scala,swift,go,rs,zig}"
  - "*.{ts,tsx,js,jsx,mjs,cjs,vue,svelte,php,dart,py,rb,lua,pl,pm,r,jl}"
  - "*.{sh,bash,zsh,fish,ps1,nix,tf,proto,gradle,sql,hs,elm,ex,exs,erl}"
  - "*.{clj,cljs,el,lisp,scm,ml,mli,fs,fsx,css,scss,less,mk,cmake}"
  - "*.{html,htm,xml,xhtml,svg,yaml,yml,toml,ini}"
  - "*.{vb,vbs,bas,pas,dpr,pp,f90,f95,f03,f08,ada,adb,ads,asm,d,mm,csh,tcsh,groovy,hcl,graphql,gql}"
  - "{Makefile,Dockerfile,*.Dockerfile}"
---

This comment shape is never the exception the policy allows. Do not write it.

Rewrite the edit without it. Do not replace it with a reworded comment — the code
line it sits on already says this, so the comment carries no information a reader
cannot get by reading one line further.

If you believe this specific case is load-bearing, it must state the *why* that is
invisible locally (a constraint, a bug worked around, a business rule), not the
*what*. A `why` never opens with `Step N`, a separator bar, an edit-history note,
a bare structural label, or a verb narrating the next statement.

Full policy: `AGENTS.md` § Comments.
