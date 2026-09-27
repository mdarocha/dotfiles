; extends

; nixvim: Lua config and raw Lua values.
(binding
  attrpath: (attrpath
    (identifier) @_path .)
  expression: (_
    (string_fragment) @injection.content)
  (#any-of? @_path "__raw" "extraConfigLua" "extraConfigLuaPre" "extraConfigLuaPost")
  (#set! injection.language "lua")
  (#set! injection.combined))

(apply_expression
  function: (_) @_func
  argument: (_
    (string_fragment) @injection.content)
  (#lua-match? @_func "mkRaw$")
  (#set! injection.language "lua")
  (#set! injection.combined))

(binding
  attrpath: (attrpath
    (identifier) @_path .)
  expression: (_
    (string_fragment) @injection.content)
  (#any-of? @_path "extraConfigVim" "extraConfigVimPre" "extraConfigVimPost")
  (#set! injection.language "vim")
  (#set! injection.combined))

; Shell snippets: mkShell, Home Manager shells, direnv.
(binding
  attrpath: (attrpath
    (identifier) @_path .)
  expression: (_
    (string_fragment) @injection.content)
  (#any-of? @_path
    "shellHook" "initExtra" "profileExtra" "logoutExtra" "bashrcExtra" "sessionVariablesExtra"
    "stdlib")
  (#set! injection.language "bash")
  (#set! injection.combined))

; Home Manager activation: lib.hm.dag.entryAnywhere ''…'', entryAfter/entryBefore [ … ] ''…''.
(apply_expression
  function: [
    (_) @_func
    (apply_expression
      function: (_) @_func)
  ]
  argument: (_
    (string_fragment) @injection.content)
  (#lua-match? @_func "dag%.entry%a+$")
  (#set! injection.language "bash")
  (#set! injection.combined))

; pkgs.writers.writePython3 "name" { libraries = …; } ''…''; upstream only matches the two-argument form.
(apply_expression
  function: (apply_expression
    function: (apply_expression
      function: (_) @_func))
  argument: (_
    (string_fragment) @injection.content)
  (#lua-match? @_func "writePy%a*%d*%a*$")
  (#set! injection.language "python")
  (#set! injection.combined))
