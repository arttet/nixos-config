# profiles/agent.nix
{ pkgs, ... }:
{
  imports = [
    ./base.nix
  ];

  # Headless AI workload
  # Optional: hardware acceleration / CUDA can be added via overlays or specific host modules
  environment.systemPackages = with pkgs; [
    python3
    pipx
    # More AI/Agent tools can be added here
  ];
}
