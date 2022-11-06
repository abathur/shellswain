{ shellswain
, shellcheck
, bats
, bats-require
, bashInteractive
, expect
}:

rec {
  upstream = shellswain.unresholved.overrideAttrs (old: {
    name = "${shellswain.name}-tests";
    dontInstall = true; # just need the build directory
    prePatch = ''
      patchShebangs tests
    '';
    installCheckInputs = [
      shellswain
      shellcheck
      (bats.withLibraries (p: [ bats-require ]))
      bashInteractive
      expect
    ];
    doInstallCheck = true;
    installCheckPhase = ''
      make check
      touch $out
    '';
  });
}
