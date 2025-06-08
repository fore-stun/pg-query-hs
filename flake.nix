{
  description = "Haskell tooling wrapping libpg_query";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    forestun.url = "github:fore-stun/flakes";
    forestun.inputs.nixpkgs.follows = "nixpkgs";

    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
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
          default = self.packages.${system}.pg_query;
          libpg_query = pkgs.callPackage ./nix/libpg_query.nix { };
          pg_query = pkgs.callPackage ./nix/pg_query.nix {
            inherit (self.packages."${system}") libpg_query;
          };
          devShell = pkgs.callPackage ./nix/shell.nix {
            inherit (self.packages."${system}") libpg_query pg_query;
          };
        };
        devShells.${system}.default = self.packages.${system}.devShell;
      }
    );
}
