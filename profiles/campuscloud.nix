# Common configuration for CMU Campus Cloud VMs
{ config, lib, ...}:
let
  cfg = config.abtech.profiles.campuscloud;
in
  {
    options.abtech.profiles.campuscloud = {
      enable = lib.mkEnableOption "Campus Cloud profile";
    };

    config = lib.mkIf cfg.enable {
      virtualisation.vmware.guest.enable = true;

      # Unified hardware configuration for campus cloud.
      boot.initrd.availableKernelModules = [ "ata_piix" "vmw_pvscsi" "floppy" "sd_mod" "sr_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ ];
      boot.extraModulePackages = [ ];

      # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
      # (the default) this is the recommended approach. When using systemd-networkd it's
      # still possible to use this option, but it's recommended to use it in conjunction
      # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
      networking.useDHCP = true;

      nixpkgs.hostPlatform = "x86_64-linux";
    };
  }