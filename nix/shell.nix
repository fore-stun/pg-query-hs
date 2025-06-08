{ lib
, haskellPackages
, pg_query
, zsh
}:

let
  name = "haskell";

  packages = builtins.attrValues {
    inherit (haskellPackages)
      cabal-gild
      cabal-install
      haskell-language-server
      hpack
      implicit-hie
      ormolu
      ;
  };

in
pg_query.env.overrideAttrs (old: {
  nativeBuildInputs = old.nativeBuildInputs ++ [ ];
  buildInputs = old.buildInputs ++ packages;
  shellHook = ''
    export NIX_SHELL_NAME="${name}"
    RPROMPT='%F{magenta}${name}%f %1(j.«%j» .)%*'
    ${zsh}/bin/zsh
    exit "$?"
  '';
})
