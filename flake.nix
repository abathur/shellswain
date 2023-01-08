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
    comity.url = "github:abathur/comity";
    bats-require = {
      url = "github:abathur/bats-require";
      follows = "comity/bats-require";
    };
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat, comity, bats-require }:
    {
      overlays.default = nixpkgs.lib.composeExtensions comity.overlays.default (final: prev: {
        shellswain = final.callPackage ./shellswain.nix { };
      });
      # shell = ./shell.nix;
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            bats-require.overlays.default
            comity.overlays.default
            self.overlays.default
          ];
        };
      in
        {
          packages = {
            inherit (pkgs) shellswain;
            default = pkgs.shellswain;
          };
          checks = pkgs.callPackages ./test.nix {
            inherit (pkgs) shellswain;
          };
        }
    );
}
