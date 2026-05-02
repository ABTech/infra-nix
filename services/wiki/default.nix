{ config, lib, pkgs, ... }:
let
  cfg = config.abtech.services.wiki;
  
  # These are hardcoded as of 26.05:
  # https://github.com/NixOS/nixpkgs/blob/fd9eef1943dc81f2877bd3e4e2ac132edd0027cc/nixos/modules/services/web-apps/mediawiki.nix#L40-L41
  mediawiki_dir = "/var/lib/mediawiki";
  # https://github.com/NixOS/nixpkgs/blob/fd9eef1943dc81f2877bd3e4e2ac132edd0027cc/nixos/modules/services/web-apps/mediawiki.nix#L31
  mediawiki_user = "mediawiki";
  # https://github.com/NixOS/nixpkgs/blob/fd9eef1943dc81f2877bd3e4e2ac132edd0027cc/nixos/modules/services/web-apps/mediawiki.nix#L32-L38
  mediawiki_group = config.services.httpd.group;

  db_dir = config.services.mysql.dataDir;
  db_user = config.services.mysql.user;
  db_group = config.services.mysql.group;
in
  {
    options.abtech.services.wiki = {
      enable = lib.mkEnableOption "abtech.services.wiki";

      domain = lib.mkOption {
        type = lib.types.str;
        default = "wiki.${config.networking.fqdn}";
        description = "Hostname to bind to";
      };
    };

    config = lib.mkIf cfg.enable {
      services.caddy = {
        enable = true;
        virtualHosts.${cfg.domain}.extraConfig =
        let
          container_ip = config.containers.wiki.localAddress;
        in ''
          reverse_proxy http://${container_ip} {
            header_down X-Real-IP {http.request.remote}
            header_down X-Forwarded-For {http.request.remote}
          }
        '';
      };

      networking.firewall.allowedTCPPorts = [ 80 443 ];

      networking.nat.enable = true;
      networking.nat.internalInterfaces = [ "ve-wiki" ];
      networking.nat.externalInterface = "ens192";

      systemd.services."container@wiki".wants = ["network-online.target"];
      systemd.services."container@wiki".after = ["network-online.target"];

      containers.wiki = {
        ephemeral = true;
        autoStart = true;

        bindMounts = {
          "/var/lib/mediawiki" = {
            hostPath = "/srv/mediawiki/";
            isReadOnly = false;
          };
          "/var/lib/mysql" = {
            hostPath = "/srv/mediawiki-mysql/";
            isReadOnly = false;
          };
          "/run/secrets/wikiInitialPassword" = {
            hostPath = config.age.secrets.wikiInitialPassword.path;
            isReadOnly = true;
          };
          "/etc/krb5.conf" = {
            hostPath = "/etc/krb5.conf";
            isReadOnly = true;
          };
        };

        privateNetwork = true;
        hostAddress = "192.168.100.2";
        localAddress = "192.168.100.11";

        config = import ./container.nix {
          config' = config;
          pkgs' = pkgs;
          domain = cfg.domain;
          passwordFile = "/run/secrets/wikiInitialPassword";
        };
      };

      # Default password: config.age.secrets.secret1.path
      age.secrets.wikiInitialPassword = {
        rekeyFile = ./initialPassword.age;
        generator.script = "passphrase";
      };

      abtech.services.index.links = [{
        name = "Wiki with krb5 auth";
        url = cfg.domain;
      }];
    };
  }