# kawari-nix

[Home manager](https://github.com/nix-community/home-manager) module to embed a file content (usually secrets) into a text file at system/home-manager activation.

This project was made because [sops-nix](https://github.com/Mic92/sops-nix) doesn't support template files when used as a home manager module

At home manager activation the templates are filled and the resulting files are stored in `$XDG_RUNTIME_DIR/kawari-nix/secrets` and linked where you need them.

## Installation

Add `kawari-nix` to your flake inputs:

```nix
{
  inputs = {
    # ...
    kawari-nix.url = "github:mducoli/kawari-nix";
  };
}
```

Import the home-manager module

```nix
{
  # NixOS system-wide home-manager configuration
  home-manager.sharedModules = [
    inputs.kawari-nix.homeManagerModule
  ];
}
```

```nix
{
  # Configuration via home.nix
  imports = [
    inputs.kawari-nix.homeManagerModule
  ];
}
```

## Usage

Here is an example usage with [sops-nix](https://github.com/Mic92/sops-nix)

```nix
kawari.template."example-app" = {
  # you can pass a path to the function kawari.placeholder to include it's content at activation
  content = ''
    password = "${inputs.kawari.placeholder config.sops.secrets.password.path}"
  '';
  # alternatively you can specify the template file path
  contentPath = "${config.xdg.configHome}/example-app/config.toml"
  # where the result will be linked to, this is the default value
  path = "${config.xdg.configHome}/kawari-nix/secrets/example-app";
  # you can specify other locations to link to
  linkTo = []; };
```

## Configuration

You can change the default directory of the links

```nix
kawari.defaultPath = "${config.xdg.configHome}/kawari-nix" # default value
```
