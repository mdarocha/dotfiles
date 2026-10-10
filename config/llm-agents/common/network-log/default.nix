{ buildGoModule }:

buildGoModule {
  pname = "agent-netlog";
  version = "0.1.0";
  src = ./.;
  vendorHash = null;
  meta.mainProgram = "agent-netlog";
}
