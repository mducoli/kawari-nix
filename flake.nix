{
  description = "Home manager module to create templates from environment files";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: rec {
    homeManagerModules = rec {
      kawari = import ./module;
      default = kawari;
    };

    homeManagerModule = homeManagerModules.kawari;
  };
}
