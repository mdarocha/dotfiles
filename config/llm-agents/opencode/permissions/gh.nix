{ config, lib, ... }:

{
  config = lib.mkIf config.mdarocha.llm-agents.enable {
    programs.opencode.settings.permission.bash = {
      # mutating operations - ask before modifying remote state

      # Issues
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
      "gh issue comment *" = "ask";
      "gh issue develop *" = "ask";

      # Pull Requests
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
      "gh pr update-branch *" = "ask";
      "gh pr revert *" = "ask";

      # Repositories
      "gh repo create *" = "ask";
      "gh repo delete *" = "deny";
      "gh repo rename *" = "ask";
      "gh repo archive *" = "ask";
      "gh repo unarchive *" = "ask";
      "gh repo edit *" = "ask";
      "gh repo fork *" = "ask";
      "gh repo sync *" = "ask";
      "gh repo set-default *" = "ask";
      "gh repo autolink add *" = "ask";
      "gh repo autolink delete *" = "ask";
      "gh repo deploy-key add *" = "deny";
      "gh repo deploy-key delete *" = "deny";

      # Releases
      "gh release create *" = "ask";
      "gh release delete *" = "ask";
      "gh release edit *" = "ask";

      # Gists
      "gh gist create *" = "ask";
      "gh gist edit *" = "ask";
      "gh gist delete *" = "ask";
      "gh gist rename *" = "ask";

      # Labels
      "gh label create *" = "ask";
      "gh label edit *" = "ask";
      "gh label delete *" = "ask";

      # Projects
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

      # GitHub Actions
      "gh run cancel *" = "ask";
      "gh run delete *" = "ask";
      "gh run rerun *" = "ask";
      "gh workflow enable *" = "ask";
      "gh workflow disable *" = "ask";
      "gh workflow run *" = "ask";

      # Caches
      "gh cache delete *" = "ask";

      # Secrets and Variables
      "gh secret set *" = "deny";
      "gh secret delete *" = "deny";
      "gh variable set *" = "ask";
      "gh variable delete *" = "ask";

      # Codespaces (cost money, can run arbitrary code)
      "gh codespace create *" = "ask";
      "gh codespace delete *" = "ask";
      "gh codespace stop *" = "ask";
      "gh codespace rebuild *" = "ask";
      "gh codespace edit *" = "ask";
      "gh codespace ssh *" = "ask";
      "gh codespace cp *" = "ask";

      # Extensions (modifies local gh installation)
      "gh extension install *" = "ask";
      "gh extension remove *" = "ask";
      "gh extension upgrade *" = "ask";
      "gh extension create *" = "ask";

      # Aliases (modifies gh config)
      "gh alias set *" = "ask";
      "gh alias delete *" = "ask";
      "gh alias import *" = "ask";

      # Raw API (can do anything - require approval)
      "gh api *" = "ask";

      # SSH/GPG keys and auth (security-critical - deny)
      "gh ssh-key add *" = "deny";
      "gh ssh-key delete *" = "deny";
      "gh gpg-key add *" = "deny";
      "gh gpg-key delete *" = "deny";

      "gh auth *" = "deny";
      "gh config set *" = "deny";
    };
  };
}
