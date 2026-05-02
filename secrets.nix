{ config, ... }:
{
  age.rekey = {
    masterIdentities = [
      {
        identity = "/Users/tuckershea/.age/abtech.age";
        pubkey = "age1ctp4vjgrd383gxx67h5fga7hm8vv9q6dj5zycn8p23wc986reghqkjhh7e";
      }
    ];

    storageMode = "local";
    localStorageDir = ./. + "/secrets/${config.networking.hostName}";
  };
}