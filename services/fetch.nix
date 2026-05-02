# A demo web app showing machine status.
{ config, lib, pkgs, ... }:
let
  cfg = config.abtech.services.fetch;

  modules_arg =
    if cfg.modules != null then
      ''--structure "${lib.strings.concatStringsSep ":" cfg.modules}"''
    else
      "";
in
  {
    options.abtech.services.fetch = {
      enable = lib.mkEnableOption "abtech.services.fetch";

      domain = lib.mkOption {
        type = lib.types.str;
        default = "fetch.${config.networking.fqdn}";
        description = "Hostname to bind to";
      };

      stateDir = lib.mkOption {
        type = lib.types.path;
        description = "Directory to store most recent output";
      };

      modules = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "Fastfetch modules";
      };
    };

    config = lib.mkIf cfg.enable {
      systemd.tmpfiles.rules =
      let
        user = "fetch";
        group = config.services.caddy.group;
      in [
        "d ${cfg.stateDir} 750 ${user} ${group} -"
      ];

      services.caddy = {
        enable = true;
        virtualHosts.${cfg.domain}.extraConfig = ''
          root ${cfg.stateDir}
          file_server
        '';
      };

      users.users.fetch = {
        isSystemUser = true;
        group = "fetch";
        description = "${cfg.domain} service user";
      };
      users.groups.fetch = {};

      systemd.timers."fetch" = {
        wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "0m";
            OnUnitActiveSec = "5m";
            Unit = "fetch.service";
          };
      };

      systemd.services."fetch" = {
        script = ''
          ${pkgs.fastfetch}/bin/fastfetch --pipe false ${modules_arg} |
            ${pkgs.aha}/bin/aha --black \
            >"${cfg.stateDir}/index.html"
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "fetch";
          Group = "fetch";
        };
      };

      networking.firewall.allowedTCPPorts = [ 80 443 ];

      abtech.services.index.links = [{
        name = "Fetch machine information";
        url = cfg.domain;
      }];
    };
  }