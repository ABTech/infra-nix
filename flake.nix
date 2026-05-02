{
  description = "AB Tech Infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    
    # Deployment dependencies
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

    # Partitioning
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-anywhere,
    agenix,
    agenix-rekey,
    disko,
    deploy-rs,
    ...
  }: let
      defaults = {
        system = "x86_64-linux";
        modules = [
          agenix.nixosModules.default
          agenix-rekey.nixosModules.default
          disko.nixosModules.disko
          ./admins.nix
          ./secrets.nix
          ./profiles/core
          ./profiles/campuscloud.nix
          ./services/fetch.nix
          ./services/index.nix
          ./services/wiki
          { nixpkgs.overlays = [self.overlays.default]; }
        ];
      };

      mkSystem = mod: nixpkgs.lib.nixosSystem {
        system = defaults.system;
        modules = defaults.modules ++ [mod];
      };

      mkDeploy = name: {
        hostname = "${name}.abtech.org";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.${name};
        };
    };
  in {
    nixosConfigurations."www-d01" = mkSystem ./hosts/www-d01;

    deploy = {
      sshUser = "tshea";
      remoteBuild = true;
    };

    deploy.nodes.www-d01 = mkDeploy "www-d01";

    # Preflight checks for connectivity
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

    # Custom packages, available to hosts as pkgs.abtech.xyz
    overlays.default = final: prev: {
      abtech = {
        mod_auth_gssapi = final.callPackage ./pkgs/mod_auth_gssapi.nix {};
        mod_authnz_pam = final.callPackage ./pkgs/mod_authnz_pam.nix {};
      };
    };
    
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
