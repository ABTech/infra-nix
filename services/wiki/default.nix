# MediaWiki, authenticated with krb5.
#
# This is a (rather nasty) demo of a native NixOS
# container. MediaWiki, httpd, PAM, etc. are running
# within the container.
#
# This file details everything in the host environment,
# and ./container.nix details everything in the container.
{ config, lib, ... }:
let
  cfg = config.abtech.services.wiki;
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

        config = {
          # Pass arguments into the container...
          _module.args = {
            domain = cfg.domain;
            passwordFile = "/run/secrets/wikiInitialPassword";
          };
          # Expose pkgs.abtech.(...) to the container
          nixpkgs.overlays = config.nixpkgs.overlays;
          # Source the container config
          imports = [
            ./container.nix
          ];
        };
      };

      # Secrets: initial password

      age.secrets.wikiInitialPassword = {
        rekeyFile = ./initialPassword.age;
        generator.script = "passphrase";
      };

      # Show on index page, if enabled

      abtech.services.index.links = [{
        name = "Wiki with krb5 auth";
        url = cfg.domain;
      }];
    };
  }