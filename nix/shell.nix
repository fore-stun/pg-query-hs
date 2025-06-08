{ lib
, haskellPackages
, pg_query
, libpg_query
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
    inherit libpg_query;
  };

in
pg_query.env.overrideAttrs (old: {
  nativeBuildInputs = old.nativeBuildInputs ++ [ ];
  buildInputs = old.buildInputs ++ packages;
  shellHook = ''
    export NIX_SHELL_NAME="${name}"
    RPROMPT='%F{magenta}${name}%f %1(j.«%j» .)%*'
    ${lib.getExe haskellPackages.cabal-install} configure \
      --disable-backup \
      --flags="-default_paths" \
      --extra-lib-dirs="${libpg_query}/lib" \
      --extra-include-dirs="${libpg_query}/include"
    ${zsh}/bin/zsh
    exit "$?"
  '';
})
