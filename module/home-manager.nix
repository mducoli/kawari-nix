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
    runtimeInputs = [pkgs.coreutils kawariSubst];
    text = ''
      # clean dirs
      SECRETS_DIR="$XDG_RUNTIME_DIR/kawari-nix/secrets.d"
      if [ -d "$SECRETS_DIR" ]; then rm -r "$SECRETS_DIR"; fi
      mkdir -p "$SECRETS_DIR"
      LINKS_DIR="${cfg.defaultPath}/secrets"
      if [ -d "$LINKS_DIR" ]; then rm -r "$LINKS_DIR"; fi

      ${forEachTemplate}
    '';
  };

  forEachTemplate = lib.concatStrings (lib.attrsets.attrValues (builtins.mapAttrs (name: value:
    /*
    bash
    */
    ''
      # subsitute and link
      mkdir -p "$(dirname -- "$SECRETS_DIR/${name}")"
      kawari-subst "${value.contentPath}" > "$SECRETS_DIR/${name}"
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
      default = "${config.xdg.configHome}/kawari-nix";
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

    systemd.user.services.kawari-nix = {
      Unit = {
        Description = "kawari-nix activation";
        After = ["sops-nix.service"]; # for compatibility
      };
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe installSecrets;
      };
      Install.WantedBy = ["default.target"];
    };

    home.activation.kawari-nix = let
      systemctl = config.systemd.user.systemctlPath;
    in ''
      systemdStatus=$(${systemctl} --user is-system-running 2>&1 || true)

      if [[ $systemdStatus == 'running' || $systemdStatus == 'degraded' ]]; then
        ${systemctl} restart --user kawari-nix
      else
        echo "User systemd daemon not running. Probably executed on boot where no manual start/reload is needed."
      fi

      unset systemdStatus
    '';
  };
}
