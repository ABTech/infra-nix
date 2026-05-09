# Administrator user account and key configuation.
#
# I make the assumption that administrators should be
# consistent across machines. If there are extraneous
# edge cases, they can just be added to the host config.
# If we end up needing to regularly reconfigure, this
# could be rewritten as a module with options.
{ config, lib, ... }:
let
  # List of admins.
  #
  # Every entry must specify a name.
  #
  # All machine administrators should include sshKey.
  #
  # All secret administrators (can decrypt secrets in
  # this repository) should include agePubkey and ageIdentityPath.
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

  # Helper lists of machine and secret admins, respectively
  sshAdmins = (builtins.filter (a: a ? sshKeys) admins);
  secretAdmins = (builtins.filter (a: a ? agePubkey) admins);
in
{
  # Make sure no one accidentally commits their age identity
  # to the store during setup! If they were to somehow,
  # it would get pushed to machines during deployment.
  assertions = (map (a: {
    assertion = !builtins.isPath a.ageIdentityPath;
    message = "Adding an identity file as an unquoted path instead of a quoted string will cause it to be committed to the store and shared in deployments. This would expose secret keys in a passwordless identity file. If you are sure you want to keep the identity in the repository, quote a relative path.";
  }) secretAdmins);

  # Set up machine accounts for administrators
  users.users = lib.listToAttrs (map (a: lib.nameValuePair a.name {
      isNormalUser = true;
      extraGroups = [ "wheel" "podman" ];
      openssh.authorizedKeys.keys = a.sshKeys;
    }) sshAdmins);

  # Set up agenix with administrators, so that they
  # can decrypt repository secrets.
  age.rekey = {
    masterIdentities = map (a: {
      identity = a.ageIdentityPath;
      pubkey = a.agePubkey;
    }) secretAdmins;
    storageMode = "local";
    localStorageDir = ./. + "/secrets/${config.networking.hostName}";
  };
}