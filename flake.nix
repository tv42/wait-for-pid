{
  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    rust-overlay = {
      url = github:oxalica/rust-overlay;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane = {
      url = "github:ipetkov/crane";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            inputs.rust-overlay.overlays.default
          ];
        };
        rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        craneLib = (inputs.crane.mkLib pkgs).overrideToolchain rustToolchain;
        commonArgs = {
          src = craneLib.cleanCargoSource ./.;
        };
        crate = craneLib.buildPackage (commonArgs // {
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;
        });
      in
      rec {
        # `nix build`
        packages.wait-for-pid = crate;
        packages.default = crate;

        # `nix run`
        apps.wait-for-pid = flake-utils.lib.mkApp {
          drv = packages.wait-for-pid;
        };
        apps.default = apps.wait-for-pid;

        # `nix develop`
        devShells.default = craneLib.devShell {
          nativeBuildInputs = with pkgs; [
          ];
        };
      });
}
