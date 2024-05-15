{
  description = "Home manager module to create templates from environment files";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    lib = nixpkgs.lib;
    systems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
      "aarch64-linux"
    ];
    forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs systems (system:
      import nixpkgs {
        inherit system;
      });
  in rec {
    homeManagerModules = rec {
      kawari = import ./module;
      default = kawari;
    };

    homeManagerModule = homeManagerModules.kawari;

    devShells = forEachSystem (pkgs: {
      default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [go gopls];
      };
    });
  };
}
