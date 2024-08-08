{ lib
, haskell
, haskellPackages
, hostPlatform
, libpg_query
}:
let

  src = lib.cleanSourceWith {
    filter = name: type:
      ! (type == "directory" && name == ".github")
    ;
    src = lib.cleanSource ../.;
  };

  pg_suffix = lib.pipe libpg_query.version [
    builtins.splitVersion
    (lib.take 3)
    (x: [
      (lib.pipe x [
        lib.init
        (lib.concatMapStrings (lib.fixedWidthNumber 2))
      ])
      (lib.last x)
    ])
    (builtins.concatStringsSep ".")
  ];

  pgQuery =
    let
      inherit (haskell.lib) compose;

      overrider = old: {
        preBuild = old.preBuild or "" + (if hostPlatform.isLinux then ''
          ln -sv "${libpg_query}/lib/libpg_query.so" "libpg_query.so.${pg_suffix}"
        '' else ''
          ln -sv "${libpg_query}/lib/libpg_query.dylib" "libpg_query.${pg_suffix}.dylib"
        '');
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
      (compose.appendConfigureFlag "--extra-lib-dirs=.")
      (drv: drv.overrideAttrs overrider)
    ]
      (haskellPackages.callCabal2nix "pg-query" src { pg_query = libpg_query; });

in
pgQuery
