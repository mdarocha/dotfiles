final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyFinal: _pyPrev: {
      jupyter_kernel_gateway = pyFinal.callPackage ./jupyter-kernel-gateway.nix { };
    })
  ];

  zsh-history-substring-search = prev.zsh-history-substring-search.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (final.writeText "history-search-preserve-highlights.patch" ''
        --- a/zsh-history-substring-search.zsh
        +++ b/zsh-history-substring-search.zsh
        @@ -115,10 +115,12 @@
           #
        -  # Dummy implementation of _zsh_highlight() that
        -  # simply removes any existing highlights when the
        -  # user inserts printable characters into $BUFFER.
        +  # On Zsh 5.9, keep other plugins' highlights when removing query highlights.
           #
           _zsh_highlight() {
             if [[ $KEYS == [[:print:]] ]]; then
        -      region_highlight=()
        +      if [[ $_history_substring_search_zsh_5_9 -eq 1 ]]; then
        +        region_highlight=( "''${(@)region_highlight:#*memo=history-substring-search*}" )
        +      else
        +        region_highlight=()
        +      fi
             fi
           }
         
      '')
    ];
  });
}
