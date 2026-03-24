{ config, lib, ... }:

{
  config = lib.mkIf config.mdarocha.llm-agents.enable {
    programs.opencode.settings.permission.bash = {
      # mutating operations - ask before modifying remote state
      "gh issue create *" = "ask";
      "gh issue close *" = "ask";
      "gh issue reopen *" = "ask";
      "gh issue delete *" = "ask";
      "gh issue edit *" = "ask";
      "gh issue transfer *" = "ask";
      "gh issue lock *" = "ask";
      "gh issue unlock *" = "ask";
      "gh issue pin *" = "ask";
      "gh issue unpin *" = "ask";

      "gh pr create *" = "ask";
      "gh pr close *" = "ask";
      "gh pr reopen *" = "ask";
      "gh pr edit *" = "ask";
      "gh pr merge *" = "ask";
      "gh pr ready *" = "ask";
      "gh pr review *" = "ask";
      "gh pr comment *" = "ask";
      "gh pr lock *" = "ask";
      "gh pr unlock *" = "ask";

      "gh repo create *" = "ask";
      "gh repo delete *" = "deny";
      "gh repo rename *" = "ask";
      "gh repo archive *" = "ask";
      "gh repo unarchive *" = "ask";
      "gh repo edit *" = "ask";
      "gh repo fork *" = "ask";

      "gh release create *" = "ask";
      "gh release delete *" = "ask";
      "gh release edit *" = "ask";

      "gh gist create *" = "ask";
      "gh gist edit *" = "ask";
      "gh gist delete *" = "ask";
      "gh gist rename *" = "ask";

      "gh label create *" = "ask";
      "gh label edit *" = "ask";
      "gh label delete *" = "ask";

      "gh project create *" = "ask";
      "gh project close *" = "ask";
      "gh project delete *" = "deny";
      "gh project edit *" = "ask";
      "gh project item-add *" = "ask";
      "gh project item-create *" = "ask";
      "gh project item-delete *" = "ask";
      "gh project item-edit *" = "ask";
      "gh project mark-template *" = "ask";
      "gh project field-create *" = "ask";
      "gh project field-delete *" = "ask";

      "gh run cancel *" = "ask";
      "gh run delete *" = "ask";
      "gh run rerun *" = "ask";
      "gh workflow enable *" = "ask";
      "gh workflow disable *" = "ask";
      "gh workflow run *" = "ask";

      "gh cache delete *" = "ask";

      "gh secret set *" = "deny";
      "gh secret delete *" = "deny";
      "gh variable set *" = "ask";
      "gh variable delete *" = "ask";

      "gh ssh-key add *" = "deny";
      "gh ssh-key delete *" = "deny";
      "gh gpg-key add *" = "deny";
      "gh gpg-key delete *" = "deny";

      "gh auth *" = "deny";
      "gh config set *" = "deny";
    };
  };
}
