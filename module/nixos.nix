{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.kawari;

  templateType = lib.types.submodule ({
    config,
    name,
    ...
  }: {
    options = {
      content = lib.mkOption {
        type = lib.types.str;
      };
      contentPath = lib.mkOption {
        type = lib.types.path;
        default = "${pkgs.writeText "kawari-template-${name}" cfg.template."${name}".content}";
      };
      path = lib.mkOption {
        type = lib.types.path;
        default = "${cfg.defaultPath}/secrets/${name}";
      };
    };
  });

  kawariSubst = pkgs.buildGoModule {
    name = "kawari-subst";
    src = ../script;
    vendorHash = null;
  };

  installSecrets = pkgs.writeShellApplication {
    name = "kawari-install-secrets";
    runtimeInputs = [pkgs.envsubst pkgs.coreutils kawariSubst];
    text = ''
      # clean dirs
      SECRETS_DIR="${cfg.defaultPath}/secrets.d"
      if [ -d "$SECRETS_DIR" ]; then rm -r "$SECRETS_DIR"; fi
      mkdir -p "$SECRETS_DIR"

      ${forEachTemplate}
    '';
  };

  forEachTemplate = lib.concatStrings (lib.attrsets.attrValues (builtins.mapAttrs (name: value:
    /*
    bash
    */
    ''
      # subsitute
      mkdir -p "$(dirname -- "$SECRETS_DIR/${name}")"
      kawari-subst "${value.contentPath}" > "$SECRETS_DIR/${name}"
      # link
      mkdir -p "$(dirname -- "${value.path}")"
      ln -sf "$SECRETS_DIR/${name}" "${value.path}"
    '')
  cfg.template));

  allUniqueValues = list: (builtins.length list) == (builtins.length (lib.lists.unique list));

  allLinkPaths = lib.attrsets.mapAttrsToList (k: v: v.path) cfg.template;
in {
  options.kawari = {
    defaultPath = lib.mkOption {
      type = lib.types.path;
      default = "/run/kawari-nix";
    };

    template = lib.mkOption {
      type = lib.types.attrsOf templateType;
      default = {};
    };
  };

  config = {
    assertions = [
      {
        assertion = allUniqueValues allLinkPaths;
        message = "Collision in kawari template path";
      }
    ];

    systemd.services.kawari-install-secrets = {
      wantedBy = ["sysinit.target"];
      after = ["systemd-sysusers.service"];
      unitConfig.DefaultDependencies = "no";

      serviceConfig = {
        Type = "oneshot";
        ExecStart = ["${lib.getExe installSecrets}"];
        RemainAfterExit = true;
      };
    };
  };
}
