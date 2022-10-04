{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
      follows = "comity/nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      follows = "comity/flake-utils";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
      follows = "comity/flake-compat";
    };
    /* TODO:
      comity = import (fetchFromGitHub {
      owner = "abathur";
      repo = "comity";
      # rev = "b6753c6c17be8b021eedffd57a6918f80b914662";
      rev = "v0.1.4";
      hash = "sha256-Hc7Vzw5gHCXASC19L9Gx5FECM4V7Vq+lX1cdBnGzFog=";
    }) { };
    */
    comity.url = "github:abathur/comity/flaky-breaky-heart";
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat, comity }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              comity = comity.packages."${system}".default;
            })
          ];
        };
      in
        {
          packages.default = pkgs.callPackage ./shellswain.nix { };
          devShell = pkgs.callPackage ./shell.nix { };
        }
    );
}
