{
  description = "My NixOS and macOS Flake Configuration";

  inputs = {
    # NixOS: stable branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS/Darwin: unstable (better darwin support)
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    home-manager-darwin = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixpkgs-darwin,
    nix-darwin,
    home-manager-darwin,
    determinate,
    ...
  } @ inputs: {
    # NixOS configurations
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos/hardware-configuration.nix
          ./hosts/nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.users.gena = import ./home/gena.nix;
            home-manager.extraSpecialArgs = { isLTWorkDevice = false; };
            home-manager.backupFileExtension = "hm-bak";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };

      nixos-hyperland = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos-hyperland/hardware-configuration.nix
          ./hosts/nixos-hyperland/configuration.nix
          # Import dank-material-shell official flake module
          inputs.dms.nixosModules.dank-material-shell
          {
            programs."dank-material-shell".dgop.package = inputs.dgop.packages."x86_64-linux".dgop;
          }
          home-manager.nixosModules.home-manager
          {
            home-manager.users.gena = import ./home/gena.nix;
            home-manager.extraSpecialArgs = { isLTWorkDevice = false; };
            home-manager.backupFileExtension = "hm-bak";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
    };

    # macOS/Darwin configurations
    darwinConfigurations = {
      workmbp = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit self; };
        modules = [
          determinate.darwinModules.default
          ./hosts/workmbp/configuration.nix
          home-manager-darwin.darwinModules.home-manager
          {
            home-manager.users.gena = import ./home/gena.nix;
            home-manager.extraSpecialArgs = { isLTWorkDevice = true; };
            home-manager.backupFileExtension = "hm-bak";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            users.users.gena = {
              name = "gena";
              home = "/Users/gena";
            };
          }
        ];
      };
    };
  };
}