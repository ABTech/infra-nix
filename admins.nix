{ pkgs, ... }:
{
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

  environment.enableAllTerminfo = true;  # tshea

  users.users.tshea = {
    isNormalUser = true;
    extraGroups = ["wheel" "podman"];
    home = "/home/tshea";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKvhvRgprAVEWlwpsd3+Zih+QZPxS8+kODRTrM5+at+W tuckershea@elmira"
    ];
  };
}