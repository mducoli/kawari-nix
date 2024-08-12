{
  description = "Home manager module to fill templates with secrets";

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

    placeholder = path: "@KAWARI:${builtins.hashString "sha256" "kawari+${path}"}:${path}:PLACEHOLDER@";

    devShells = forEachSystem (pkgs: {
      default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [go gopls];
      };
    });
  };
}
