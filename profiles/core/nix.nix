{ lib, config, ... }:
lib.mkIf config.abtech.profiles.core.enable {
  nix = {
    channel.enable = false;
    settings = {
      experimental-features = ["nix-command" "flakes"];

      # Make builds on-machine with major dependency
      # bumps more likely to succeed, as they are likely
      # to pull a lot from the cache.
      download-buffer-size = 500000000;  # 500 MB
    };
    
    # Automatically shrink store size over time by
    # running the optimizer (hardlink common files)
    # and the garbage collector.
    optimise.automatic = true;
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  system.autoUpgrade = {
    enable = true;
    flake = "github:abtech/infra-nix";
    dates = "03:00";
    randomizedDelaySec = "45min";
    allowReboot = true;
    rebootWindow = {
      lower = "02:00";
      upper = "05:00";
    };
  };
}