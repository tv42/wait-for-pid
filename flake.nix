{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, utils, naersk }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages."${system}";
        naersk-lib = naersk.lib."${system}";
      in
      rec {
        # `nix build`
        packages.wait-for-pid = naersk-lib.buildPackage {
          pname = "wait-for-pid";
          root = ./.;
        };
        defaultPackage = packages.wait-for-pid;

        # `nix run`
        apps.wait-for-pid = utils.lib.mkApp {
          drv = packages.wait-for-pid;
        };
        defaultApp = apps.wait-for-pid;

        # `nix develop`
        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ rustc cargo ];
        };
      });
}
