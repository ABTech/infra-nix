{ config, pkgs, lib, ... }:
let
  admins = [
    {
      name = "tshea";
      sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKvhvRgprAVEWlwpsd3+Zih+QZPxS8+kODRTrM5+at+W tuckershea@elmira"
      ];
      agePubkey = "age1ctp4vjgrd383gxx67h5fga7hm8vv9q6dj5zycn8p23wc986reghqkjhh7e";
      ageIdentityPath = "/Users/tuckershea/.age/abtech.age";
    }
  ];

  sshAdmins = (builtins.filter (a: a ? sshKeys) admins);
  secretAdmins = (builtins.filter (a: a ? agePubkey) admins);
in
{
  assertions = (map (a: {
    assertion = !builtins.isPath a.ageIdentityPath;
    message = "Adding an identity file as an unquoted path instead of a quoted string will cause it to be committed to the store. This would expose secret keys in a passwordless identity file. If you are sure you want to keep the identity in the repository, quote a relative path";
  }) secretAdmins);

  users.users = lib.listToAttrs (map (a: lib.nameValuePair a.name {
      isNormalUser = true;
      extraGroups = [ "wheel" "podman" ];
      openssh.authorizedKeys.keys = a.sshKeys;
    }) sshAdmins);

  age.rekey = {
    masterIdentities = map (a: {
      identity = a.ageIdentityPath;
      pubkey = a.agePubkey;
    }) secretAdmins;
    storageMode = "local";
    localStorageDir = ./. + "/secrets/${config.networking.hostName}";
  };
}