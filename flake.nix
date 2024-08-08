{
  description = "Haskell tooling wrapping libpg_query";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    forestun.url = "github:fore-stun/flakes";
    forestun.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, forestun, ... }:
    let
      inherit (forestun) lib;
    in
    lib.foldFor [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
          forestun.overlays.default
        ];
      in
      {
        packages.${system} = {
          pg_query = pkgs.callPackage ./nix/pg_query.nix { };
          devShell = self.packages.${system}.pg_query.env;
        };
        devShells.${system}.default = self.packages.${system}.devShell;
      }
    );
}
