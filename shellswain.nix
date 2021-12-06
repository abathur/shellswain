# with import <nixpkgs> {};
{ stdenv, lib, resholvePackage, fetchFromGitHub, pkgs, bashInteractive_5, doCheck ? true, shellcheck }:

let
  comity = import (fetchFromGitHub {
    owner = "abathur";
    repo = "comity";
    # rev = "b6753c6c17be8b021eedffd57a6918f80b914662";
    rev = "v0.1.1";
    hash = "sha256-qlGrLRjnKaN2s95OR+nw0ilOh7Ky8rWIRyUR9fYN0V8=";
  }) { };
in
resholvePackage rec {
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

  solutions = {
    profile = {
      scripts = [ "bin/shellswain.bash" ];
      interpreter = "none";
      inputs = [ comity ];
    };
  };

  makeFlags = [ "prefix=${placeholder "out"}" ];

  inherit doCheck;
  checkInputs = [ shellcheck ];

  meta = with lib; {
    description = "Bash library supporting simple event-driven bash profile scripts & modules";
    homepage = https://github.com/abathur/shellswain;
    license = licenses.mit;
    maintainers = with maintainers; [ abathur ];
    platforms = platforms.all;
  };
}
