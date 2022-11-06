# with import <nixpkgs> {};
{ lib
, resholve
, comity
, callPackage
}:

resholve.mkDerivation rec {
  pname = "shellswain";
  version = "unreleased";

  src = lib.cleanSource ./.;
  # src = fetchFromGitHub {
  #   owner = "abathur";
  #   repo = "shellswain";
  #   rev = "b6753c6c17be8b021eedffd57a6918f80b914662";
  #   # rev = "v${version}";
  #   sha256 = "0jninx8aasa83g38qdpzy86m71xkpk7dzz8fvnab3lyk9fll4jk0";
  # };
  # src = lib.cleanSource ../../../../work/shellswain;

  prePatch = ''
    patchShebangs tests
  '';

  solutions = {
    profile = {
      scripts = [ "bin/shellswain.bash" ];
      interpreter = "none";
      inputs = [ comity ];
    };
  };

  makeFlags = [ "prefix=${placeholder "out"}" ];

  doCheck = false;

  # TODO: below likely needs fixing
  passthru.tests = callPackage ./test.nix { };

  meta = with lib; {
    description = "Bash library supporting simple event-driven bash profile scripts & modules";
    homepage = https://github.com/abathur/shellswain;
    license = licenses.mit;
    maintainers = with maintainers; [ abathur ];
    platforms = platforms.all;
  };
}
