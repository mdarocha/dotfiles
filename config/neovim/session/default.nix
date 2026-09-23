# Sessions: auto-session saves and restores open files per working directory.
{ ... }:
{
  # auto-session needs localoptions to restore filetype and highlighting.
  opts.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions";

  # Skip scratch panes on save so restored sessions contain real files. The dashboard
  # isn't bypassed, so quitting with every buffer closed deletes the session.
  plugins.auto-session = {
    enable = true;
    settings = {
      bypass_save_filetypes = [
        "NvimTree"
        "aerial"
        "snacks_terminal"
        "prompt"
        "help"
      ];
      close_filetypes_on_save = [
        "checkhealth"
        "NvimTree"
        "aerial"
        "snacks_terminal"
        "snacks_picker_input"
        "snacks_picker_list"
        "snacks_picker_preview"
      ];
    };
  };
}
