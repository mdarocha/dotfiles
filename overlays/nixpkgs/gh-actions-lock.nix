{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:

buildGoModule (finalAttrs: {
  pname = "gh-actions-lock";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "github";
    repo = "gh-actions-lock";
    tag = "v${finalAttrs.version}";
    hash = "sha256-hbduX3k4PHJzGj9o84EcDV2+tYedXVB1FW1clHQslAs=";
  };

  vendorHash = "sha256-MS0GDAo/COikI5LwfgNPR83MhY6fAFg+Lpmzkv86X3M=";

  subPackages = [ "cmd/gh-actions-lock" ];

  ldflags = [ "-s" ];

  meta = {
    description = "GitHub CLI extension that generates and verifies GitHub Actions lockfiles";
    homepage = "https://github.com/github/gh-actions-lock";
    changelog = "https://github.com/github/gh-actions-lock/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "gh-actions-lock";
  };
})
