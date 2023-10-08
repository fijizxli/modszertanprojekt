{ config, lib, options, pkgs, ... }:
let
  inherit (lib)
    attrValues
    mkIf
    mkOption
    mkMerge
    types
    ;

  cfg = config.virtualisation.arion;

  projectType = types.submoduleWith {
    modules = [ projectModule ];
  };

  projectModule = { config, name, ... }: {
    options = {
      settings = mkOption {
        description = ''
          Arion project definition, otherwise known as arion-compose.nix contents.

          See <link xlink:href="https://docs.hercules-ci.com/arion/options/">https://docs.hercules-ci.com/arion/options/</link>.
        '';
        type = arionSettingsType name;
        visible = "shallow";
      };
      _systemd = mkOption { internal = true; };
    };
    config = {
      _systemd.services."arion-${name}" = {
        wantedBy = [ "multi-user.target" ];
        after = [ "sockets.target" ];

        path = [
          cfg.package
          cfg.docker.client.package
        ];
        environment.ARION_PREBUILT = config.settings.out.dockerComposeYaml;
        script = ''
          echo 1>&2 "docker compose file: $ARION_PREBUILT"
          arion --prebuilt-file "$ARION_PREBUILT" up
        '';
      };
    };
  };

  arionSettingsType = name:
    (cfg.package.eval { modules = [{ project.name = lib.mkDefault name; }]; }).type or (
      throw "lib.evalModules did not produce a type. Please upgrade Nixpkgs to nixos-unstable or >=nixos-21.11"
    );

in
{
  disabledModules = [ "virtualisation/arion.nix" ];

  options = {
    virtualisation.arion = {
      backend = mkOption {
        type = types.enum [ "podman-socket" "docker" ];
        description = ''
          Which container implementation to use.
        '';
      };
      package = mkOption {
        type = types.package;

        default = (import ./. { inherit pkgs; }).arion;
        description = ''
          Arion package to use. This will provide <literal>arion</literal>
          executable that starts the project.

          It also must provide the arion <literal>eval</literal> function as
          an attribute.
        '';
      };
      docker.client.package = mkOption {
        type = types.package;
        internal = true;
      };
      projects = mkOption {
        type = types.attrsOf projectType;
        default = { };
        description = ''
          Arion projects to be run as a service.
        '';
      };
    };
  };

  config = mkIf (cfg.projects != { }) (
    mkMerge [
      {
        systemd = mkMerge (map (p: p._systemd) (attrValues cfg.projects));
      }
      (mkIf (cfg.backend == "podman-socket") {
        virtualisation.docker.enable = false;
        virtualisation.podman.enable = true;
        virtualisation.podman.dockerSocket.enable = true;
        virtualisation.podman.defaultNetwork = 
          if options?virtualisation.podman.defaultNetwork.settings
          then { settings.dns_enabled = true; } # since 2023-01 https://github.com/NixOS/nixpkgs/pull/199965
          else { dnsname.enable = true; }; # compat <2023

        virtualisation.arion.docker.client.package = pkgs.docker-client;
      })
      (mkIf (cfg.backend == "docker") {
        virtualisation.docker.enable = true;
        virtualisation.arion.docker.client.package = pkgs.docker;
      })
    ]
  );
}
