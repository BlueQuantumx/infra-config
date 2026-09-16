# Applies this flake's nixpkgs overlays to a NixOS host. Declared once here
# instead of in every host configuration.
{ inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.self.overlays.modifications
    inputs.self.overlays.unstable-packages
  ];
}
