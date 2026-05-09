{
  description = "AB Tech Infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    
    # Deployment tooling
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Imaging new machines
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixos-stable.follows = "nixpkgs";
      inputs.disko.follows = "disko";
    };

    # Secrets
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";

    # Disk partitioning and formatting
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    deploy-rs,
    nixos-anywhere,
    agenix,
    agenix-rekey,
    disko,
    ...
  }: let
      # List all members of a directory (non-recursive)
      # (not including . and ..).
      ls = path: (map
        (name: path + "/${name}")
        (builtins.attrNames (builtins.readDir path))
      );

      # Some standard configuration for hosts.
      # In particular, we're expecting most to
      # be amd64 and linux (not darwin/MacOS),
      # and we want all hosts to import relevant
      # flake inputs, modules, and shared defaults.
      defaults = {
        system = "x86_64-linux";
        modules = [
          # External modules used in configs
          agenix.nixosModules.default
          agenix-rekey.nixosModules.default
          disko.nixosModules.disko
          # Administrator users and keys
          ./admins.nix
          # Module to apply this flake's `default` overlay.
          # This adds packages to the `pkgs.abtech.(...)`
          # namespace.
          { nixpkgs.overlays = [self.overlays.default]; }
        ]
        # Every module in ./profiles and ./services
        ++ (ls ./profiles)
        ++ (ls ./services)
        ;
      };

      # Helper function: make a default NixOS configuration
      # and import an additional module (from ./hosts/).
      mkSystem = mod: nixpkgs.lib.nixosSystem {
        system = defaults.system;
        modules = defaults.modules ++ [mod];
      };

      # Helper function: make a default deploy-rs deployment.
      # 
      # The name argument should match the configuration name.
      # Generally, all hosts should get a deploy entry.
      #
      # deploy-rs needs a hostname to target, which should always
      # be the machine name, and at least one profile. Since we
      # aren't managing several independent users, we can make
      # one profile for the system-wide configuration (root).
      mkDeploy = name: {
        hostname = "${name}.abtech.org";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.${name};
        };
    };
  in {
    # One entry per host:
    # nixosConfigurations.$HOSTNAME = mkSystem ./hosts/$HOSTNAME
    #                                      (or ./hosts/$HOSTNAME.nix)
    #
    # Ensure that you create the file $HOSTNAME.nix with config,
    # or a directory $HOSTNAME containing default.nix, in ./hosts/.
    #
    # Will need to write a more verbose definition for systems
    # on ARM or Darwin, but I'm not expecting that to be pressing.
    nixosConfigurations."www-d01" = mkSystem ./hosts/www-d01;

    # One entry per host:
    # deploy.nodes.$HOSTNAME = mkDeploy $HOSTNAME
    deploy.nodes.www-d01 = mkDeploy "www-d01";

    # Preflight checks: trying to statically ensure machines can be
    # connected to and administered.
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

    # Custom packages, available to hosts as pkgs.abtech.$NAME
    overlays.default = final: prev: {
      abtech = {
        mod_auth_gssapi = final.callPackage ./pkgs/mod_auth_gssapi.nix {};
        mod_authnz_pam = final.callPackage ./pkgs/mod_authnz_pam.nix {};
        mediawiki-AuthRemoteUser = final.callPackage ./pkgs/mediawiki-authremoteuser.nix {};
      };
    };
    
    # Secret module configuration. Run `agenix --help`.
    agenix-rekey = agenix-rekey.configure {
      userFlake = self;
      nixosConfigurations = self.nixosConfigurations;
    };
  
    # Run `nix develop` to get a shell with all
    # deployment dependencies
    devShells = nixpkgs.lib.genAttrs
      [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ]
      (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          packages = [
            # orchestrator
            deploy-rs.packages.${system}.default
            # nixos-anywhere: Remote machine imaging
            nixos-anywhere.packages.${system}.nixos-anywhere
            # ssh-keyscan and ssh-to-age for machine keying
            pkgs.ssh-to-age
            # secret generation and encryption
            agenix-rekey.packages.${system}.default
          ];
        };
      });
  };
}
