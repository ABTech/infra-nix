# Demo webpage listing machine services.
#
# Other services on this machine should configure:
#
#   abtech.services.index.links = [{
#     name = "What this app does";
#     url = "abc.xyz";
#   }];
{ config, lib, pkgs, ... }:
let
  cfg = config.abtech.services.index;

  linkType = lib.types.submodule ({ config, ... }: {
    options = {
      name = lib.mkOption {
        description = "The service name";
        type = lib.types.str;
        default = config.url;
      };
      url = lib.mkOption {
        description = "A url to the service";
        type = lib.types.str;
      };
    };
  });
in
  {
    options.abtech.services.index = {
      enable = lib.mkEnableOption "abtech.services.index";

      domain = lib.mkOption {
        type = lib.types.str;
        default = "${config.networking.fqdn}";
        description = "Hostname to bind to";
      };

      links = lib.mkOption {
        type = lib.types.listOf linkType;
        description = "Pages to link out to";
      };
    };

    config = lib.mkIf cfg.enable {
      services.caddy = {
        enable = true;
        virtualHosts.${cfg.domain}.extraConfig =
        let
          mkLink = { name, url }: ''<li><a href="https://${url}">${name}</a></li>'';
          wwwDir = pkgs.writeTextDir "index.html" ''
<!DOCTYPE html>
<html>
  <head>
    <title>Index / ${cfg.domain}</title>
  </head>
  <body>
    <ul>
      ${lib.concatStrings (map mkLink cfg.links)}
    </ul>
  </body>
</html>
          '';
        in ''
          root ${wwwDir}
          file_server
        '';
      };

      networking.firewall.allowedTCPPorts = [ 80 443 ];
    };
  }