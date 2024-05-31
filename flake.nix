{
  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    rust-overlay = {
      url = github:oxalica/rust-overlay;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gitignore = {
      url = github:hercules-ci/gitignore;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, naersk, gitignore }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        rustVersionOverlay = (self: prev:
          let
            rustChannel = prev.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
          in
          {
            rustc = rustChannel;
            cargo = rustChannel;
          }
        );
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            rust-overlay.overlays.default
            rustVersionOverlay
          ];
        };
        naersk-lib = naersk.lib.${system}.override {
          rustc = pkgs.rustc;
          cargo = pkgs.cargo;
        };
        gitignoreSource = gitignore.outputs.lib.gitignoreSource;
      in
      rec {
        # `nix build`
        packages.wait-for-pid = naersk-lib.buildPackage {
          pname = "wait-for-pid";
          # Avoid ingesting all of `target/` into the Nix store.
          src = gitignoreSource ./.;
        };
        defaultPackage = packages.wait-for-pid;

        # `nix run`
        apps.wait-for-pid = flake-utils.lib.mkApp {
          drv = packages.wait-for-pid;
        };
        defaultApp = apps.wait-for-pid;

        # `nix develop`
        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            rustc
            cargo
          ];
        };
      });
}
