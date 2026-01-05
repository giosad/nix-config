{
  description = "My NixOS and macOS Flake Configuration";

  inputs = {
    # NixOS: stable branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
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
    # NixOS configuration
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos/hardware-configuration.nix
          ./hosts/nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.users.gena = import ./home/gena.nix;
            home-manager.backupFileExtension = "hm-bak";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
    };

    # macOS/Darwin configuration
    darwinConfigurations = {
      workmbp = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit self; };
        modules = [
          determinate.darwinModules.default
          ./hosts/workmbp/configuration.nix
          # home-manager-darwin.darwinModules.home-manager
          # {
          #   home-manager.users.gena = import ./home/gena.nix;
          #   home-manager.backupFileExtension = "hm-bak";
          #   home-manager.useGlobalPkgs = true;
          #   home-manager.useUserPackages = true;
          # }
        ];
      };
    };
  };
}