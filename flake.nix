{
  description = "personal dotfiles";

  nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://mdarocha-dotfiles.cachix.org"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "mdarocha-dotfiles.cachix.org-1:kBGT+0RREXqBc0Z7hI9NdvjrA7ypIpIhMLNrD1qLF9k="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents.url = "github:numtide/llm-agents.nix";

    # Own fork, maintained independently — upstream (archie-judd/agent-sandbox.nix)
    # rewrote the launcher in Python (v3.0.0+) with no allowGpu equivalent, so this
    # tracks fork main rather than upstream. See mdarocha/agent-sandbox.nix#2 for
    # the plan to adopt the upstream rewrite.
    agent-sandbox = {
      url = "github:mdarocha/agent-sandbox.nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    humanizer = {
      url = "github:blader/humanizer";
      flake = false;
    };

    anthropics-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };

    oh-my-zsh = {
      url = "github:ohmyzsh/ohmyzsh/master";
      flake = false;
    };

    zsh-vanilli = {
      url = "github:yous/vanilli.sh/master";
      flake = false;
    };

    zsh-windows-title = {
      url = "github:mdarocha/zsh-windows-title/master";
      flake = false;
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [
        ./flake-modules/home-configurations.nix
        ./flake-modules/checks.nix
        ./flake-modules/apps.nix
      ];

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt-tree;
        };
    };
}
