{ config, lib, pkgs, ...}:
let
  cfg = config.abtech.profiles.core;
in
  {
    imports = [
      ./nix.nix
      ./packages.nix
    ];
    
    options.abtech.profiles.core = {
      enable = lib.mkEnableOption "abtech.profiles.core"
                // { default = true; };
    };

    config = lib.mkIf cfg.enable {
      networking.domain = "abtech.org";
      
      time.timeZone = "America/New_York";
      i18n.defaultLocale = "en_US.UTF-8";

      services.openssh.enable = true;
      services.fail2ban = {
        enable = true;
        ignoreIP = [
          # CMU allocations
          "128.2.0.0/16" "128.237.0.0/16"
          # Mousetrap static IP
          "108.39.140.52/32"
          # Private IP ranges
          "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16"
        ];
      };

      # Annoying bug in 25.11 that causes the
      # logrotate configuration checks to fail
      # during build.
      services.logrotate.checkConfig = false;
  
      # Allow users to log in via Kerberos
      # if they are already provisioned.
      security.krb5 = {
        enable = true;
        settings.include = ./krb5.conf;
      };
      security.pam.krb5.enable = true;

      # Default SSH package is built without krb5.
      programs.ssh.package = pkgs.openssh_gssapi;
      services.openssh.extraConfig = ''
        KerberosAuthentication yes
        GSSAPIAuthentication yes
      '';

      # Open for collecting statistics.
      services.prometheus.exporters = {
        node = {
          enable = true;
          openFirewall = true;
          enabledCollectors = [
            "systemd"
            "tcpstat"
          ];
        };
      };

      # Sudo users can also switch the system (deploy)
      nix.settings.trusted-users = [ "root" "@wheel" ];

      # abtech logo on SSH login!
      users.motd = builtins.fromJSON (builtins.readFile ./motd.json);

      # Podman support on all machines
      boot.enableContainers = true;
      virtualisation = {
        containers.enable = true;
        oci-containers.backend = "podman";

        podman = {
          enable = true;
          dockerCompat = true;
          defaultNetwork.settings.dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
        };
      };
    };
  }