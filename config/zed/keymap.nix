[
  {
    bindings = {
      # docks
      "alt-c" = "workspace::ToggleCenteredLayout";
      "alt-l" = "workspace::ToggleLeftDock";
      "alt-r" = "workspace::ToggleRightDock";
      "alt-b" = "workspace::ToggleBottomDock";
      # navigate between all panes
      "ctrl-w h" = "workspace::ActivatePaneLeft";
      "ctrl-w l" = "workspace::ActivatePaneRight";
      "ctrl-w k" = "workspace::ActivatePaneUp";
      "ctrl-w j" = "workspace::ActivatePaneDown";
    };
  }
  {
    context = "Editor && vim_mode == normal && editor_agent_diff";
    bindings = {
      "g y" = "agent::Keep";
      "g n" = "agent::Reject";
    };
  }
  {
    context = "Editor";
    bindings = {
      "ctrl-k" = "editor::ShowSignatureHelp";
      # reset tab to original behaviour, without edit predictions
      "tab" = "editor::Tab";
    };
  }
  # reset tab to original behaviour without edit predictions, for vim mode
  {
    context = "(VimControl && !menu) || vim_mode == replace || vim_mode == waiting";
    bindings = {
      "tab" = "vim::Tab";
    };
  }
  {
    context = "vim_mode == literal";
    bindings = {
      "tab" = [
        "vim::Literal"
        [
          "tab"
          "\u0009"
        ]
      ];
    };
  }
  {
    context = "Editor && edit_prediction";
    bindings = {
      "ctrl-y" = "editor::AcceptEditPrediction";
    };
  }
  {
    context = "(Editor && edit_prediction_conflict)";
    bindings = {
      "ctrl-y" = "editor::AcceptEditPrediction";
    };
  }
  {
    context = "Editor && vim_mode == normal";
    bindings = {
      # lsp
      "shift-k" = "editor::Hover";
      "alt-enter" = "editor::ToggleCodeActions";
      "ctrl-]" = "editor::GoToImplementation";
      "\\ r" = "editor::Rename";
      "g r" = "editor::FindAllReferences";
      "g d" = "editor::GoToDefinition";
    };
  }
]
