{ shellswain
, shellcheck
, bats
, bashInteractive
, socat
}:

rec {
  upstream = shellswain.unresholved.overrideAttrs (old: {
    name = "${shellswain.name}-tests";
    dontInstall = true; # just need the build directory
    installCheckInputs = [ shellswain shellcheck bats bashInteractive socat ];
    doInstallCheck = true;
    installCheckPhase = ''
      ${bats}/bin/bats tests
      touch $out
    '';
  });
}
