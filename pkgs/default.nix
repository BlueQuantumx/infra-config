# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  hust-network-login = pkgs.callPackage ./hust-network-login { };
}
