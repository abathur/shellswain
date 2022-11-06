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
    comity.url = "github:abathur/comity/flaky-breaky-heart";
    bats-require = {
      url = "github:abathur/bats-require";
      follows = "comity/bats-require";
    };
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat, comity, bats-require }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              comity = comity.packages."${system}".default;
              bats-require = bats-require.packages."${system}".default;
            })
          ];
        };
      in rec {
          packages.shellswain = pkgs.callPackage ./shellswain.nix { };
          packages.default = self.packages.${system}.shellswain;
          checks = pkgs.callPackages ./test.nix {
            inherit (packages) shellswain;
          };
          # devShell = pkgs.callPackage ./shell.nix { };
        }
    );
}
