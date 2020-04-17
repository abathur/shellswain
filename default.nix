#with import <nixpkgs> {};
{ stdenv, lib, resholved, fetchFromGitHub, pkgs, bashInteractive_5, doCheck ? true, shellcheck }:

resholved.buildResholvedPackage rec {
  pname = "shellswain";
  version = "unreleased";

  src = fetchFromGitHub {
    owner = "abathur";
    repo = "shellswain";
    rev = "9ac54210537c7ac6d6d1c8438c6a10d6e935a5fc";
    # rev = "v${version}";
    sha256 = "1524f4k2qa8wcc6wdqkckijkahz44057d0vrmcy923pxa3rx804s";
  };
  # src = lib.cleanSource ../../../../work/shellswain;

  scripts = [ "shellswain.bash" ];
  inputs = [ pkgs.bashup-events44 ];

  makeFlags = [ "prefix=${placeholder "out"}" ];

  inherit doCheck;
  checkInputs = [ shellcheck ];

  meta = with stdenv.lib; {
    description = "Bash library supporting simple event-driven bash profile scripts & modules";
    homepage = https://github.com/abathur/shellswain;
    license = licenses.mit;
    maintainers = with maintainers; [ abathur ];
    platforms = platforms.all;
  };
}
