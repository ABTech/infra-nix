{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./disks.nix
  ];

  abtech.profiles.campuscloud.enable = true;
  networking.hostName = "www-d01";

  abtech.services.index = {
    enable = true;
    domain = "nix-demo.abtech.org";
  };

  abtech.services.fetch = {
    enable = true;
    domain = "fetch.nix-demo.abtech.org";
    stateDir = "/srv/fetch/";
  };

  abtech.services.wiki = {
    enable = true;
    domain = "wiki.nix-demo.abtech.org";
  };

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGTYit+oKuGnp+7+QWhWntmU/v4ZGsjHsuS6TURh3udm www-d01.abtech.org";

  programs.bash.promptInit = ''
    PS1_PROD="\[\033[41m\]\[\033[37m\] PROD \[\033[0m\]"
    PS1_HOST="\[\033[1;32m\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\[\033[0m\]"
    PS1="$PS1_PROD $PS1_HOST > "
  '';

  system.stateVersion = "25.11";
}