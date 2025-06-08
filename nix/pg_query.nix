{ lib
, haskell
, haskellPackages
, hostPlatform
, libpg_query
}:
let

  src = let fs = lib.fileset; root = ../.; in fs.toSource {
    inherit root;
    fileset = fs.intersection
      (fs.fromSource
        (lib.cleanSourceWith {
          filter = lib.cleanSourceFilter;
          src = lib.cleanSource ../.;
        }))
      (fs.fileFilter (f: f.name != ".github") root)
    ;
  };

  pg_suffix = libpg_query.passthru.pg_suffix;

  pgQuery =
    let
      inherit (haskell.lib) compose;

      overrider = old: {
        postFixup = old.postFixup or "" + (if hostPlatform.isLinux then ''
          patchelf \
            --replace-needed "libpg_query.so.${pg_suffix}" "${libpg_query}/lib/libpg_query.so" \
            "$out/bin/example"
        '' else ''
          /usr/bin/install_name_tool -change "libpg_query.${pg_suffix}.dylib" \
            "${libpg_query}/lib/libpg_query.dylib" "$out/bin/example"

          /usr/bin/codesign --force -s - "$out/bin/example"
        '');
      };

    in
    lib.flip lib.pipe [
      (compose.disableCabalFlag "default_paths")
      (compose.appendConfigureFlag "--extra-lib-dirs=${libpg_query}/lib")
      (compose.appendConfigureFlag "--extra-include-dirs=${libpg_query}/include")
      (drv: drv.overrideAttrs overrider)
    ]
      (haskellPackages.callCabal2nix "pg-query" src { pg_query = libpg_query; });

in
pgQuery
