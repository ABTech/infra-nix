{ config, pkgs, lib, passwordFile, domain, pkgs', ... }:
let
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
in {
  systemd.tmpfiles.rules = [
    "d ${mediawiki_dir} 700 ${mediawiki_user} ${mediawiki_group} -"
    "d ${db_dir} 700 ${db_user} ${db_group} -"
  ];

  services.mediawiki = {
    enable = true;
    inherit passwordFile;
    extensions = {
      PluggableAuth = pkgs.fetchzip {
        url = "https://gerrit.wikimedia.org/r/plugins/gitiles/mediawiki/extensions/PluggableAuth/+archive/e66a4b045b91b46bc31bf05c03bafc9aed974a20.tar.gz";
        sha256 = "sha256-R9EMxR8d2W5YX9SnndvBgkw+02cBxp/inBo3RQcpe4s=";
        stripRoot = false;
      };
      AuthRemoteUser = pkgs.abtech.mediawiki-AuthRemoteUser;
    };
    httpd.virtualHost = {
      hostName = "${domain}";
      adminAddr = "webmaster@${domain}";
      listen = [{
        ip = "*";
        port = 80;
      }];
      extraConfig = ''
        <Location "/">
          AuthType Basic
          AuthName "Kerberos Login"
          AuthBasicProvider PAM
          AuthPAMService httpd-wiki
          Require valid-user
        </Location>
      '';
    };
    extraConfig = ''
      $wgShowExceptionDetails = true;
      wfLoadExtension( 'PluggableAuth' );
      wfLoadExtension( 'AuthRemoteUser' );

      $wgAuthRemoteuserAllowUserSwitch = false;          # don't let users log out and become someone else
      $wgAuthRemoteuserUserPrefsForced = [
          'realname' => '$username',
      ];
      # Optional: strip a Kerberos realm if REMOTE_USER looks like alice@EXAMPLE.COM
      $wgAuthRemoteuserUserName = [
          fn ( $username ) => preg_replace( '/@.*$/', ''', $username ),
      ];
      $wgGroupPermissions['*']['autocreateaccount'] = true;
    '';
  };

  systemd.services.mediawiki-bootstrap-admins = let
    admins = [ "tshea" ];
  in {
      description = "Promote configured users to sysop+bureaucrat";
      after = [ "mediawiki-init.service" "phpfpm-mediawiki.service" ];
      wants = [ "mediawiki-init.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = mediawiki_user;
        Group = mediawiki_group;
      };

      script = ''
        export MEDIAWIKI_CONFIG="${config.services.phpfpm.pools.mediawiki.phpEnv.MEDIAWIKI_CONFIG}"
        # For each admin user: run createAndPromote
        ${lib.concatMapStringsSep "\n" (u: ''
          ${config.services.mediawiki.phpPackage}/bin/php ${config.services.mediawiki.finalPackage}/share/mediawiki/maintenance/run.php \
            createAndPromote \
            --sysop --bureaucrat --force \
            ${lib.escapeShellArg u}
        '') admins}
      '';
    };

  # Authentication via Apache -> PAM -> krb5

  services.httpd.extraModules =
    [{
      name = "authnz_pam";
      path = "${pkgs.abtech.mod_authnz_pam}/modules/mod_authnz_pam.so";
    }];

  environment.etc."pam.d/httpd-wiki".text = ''
    auth required ${pkgs.pam_krb5}/lib/security/pam_krb5.so
    account required ${pkgs.pam_krb5}/lib/security/pam_krb5.so
  '';

  security.krb5 = { enable = true; };
  security.pam.krb5.enable = true;
  
  networking.firewall.allowedTCPPorts = [ 80 ];

  system.stateVersion = "25.11";
}
