{ lib
, hostPlatform
, libpg_query
, lndir
, runCommand

, pg_suffix ? lib.pipe libpg_query.version [
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
  ]
}:

runCommand "libpg_query_haskell" { passthru = { inherit pg_suffix; }; } ''
  mkdir -p "$out"
  ${lib.getExe lndir} -silent ${libpg_query} "$out"
  ${if hostPlatform.isLinux then ''
  ln -sv "${libpg_query}/lib/libpg_query.so" "$out/lib/libpg_query.so.${pg_suffix}"
  '' else ''
  ln -sv "${libpg_query}/lib/libpg_query.dylib" "$out/lib/libpg_query.${pg_suffix}.dylib"
  ''
  }
''
