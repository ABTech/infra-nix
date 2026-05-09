{
  ...
}: {
  imports = [
    ./disks.nix
  ];

  abtech.profiles.campuscloud.enable = true;

  # hostname is prescribed; should match path
  networking.hostName = "www-d01";
  # pubkey is taken from the machine after setup.
  # e.g. via `ssh-keyscan`.
  # After setting a pubkey, rekey secrets to the device.
  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGTYit+oKuGnp+7+QWhWntmU/v4ZGsjHsuS6TURh3udm www-d01.abtech.org";

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

  # DO NOT CHANGE
  system.stateVersion = "25.11";
}