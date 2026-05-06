{ config, lib, pkgs, ... }:
lib.mkIf config.abtech.profiles.core.enable {
  environment.systemPackages = with pkgs; [
    # Essentials
    cowsay
    fastfetch
    sl

    # Network/Web Utilities
    netcat
    nmap
    w3m         # merichar
    wget

    # File Utilities
    git
    unzip
    xz

    # Monitoring/Debugging
    dmidecode
    htop
    lsb-release
    pciutils
    strace
    usbutils

    # Editors
    emacs       # merichar
    helix       # tshea
    nano        # pnaseck
    neovim
    vim

    # Multiplexers
    screen      # merichar/pnaseck
    tmux        # tshea

    # Other...
    moreutils   # pnaseck
    gnupg       # pnaseck
  ];

  # xterm-kitty TERMINFO etc.
  environment.enableAllTerminfo = true;  # tshea
}