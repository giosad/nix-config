{
  description = "My NixOS Flake Configuration";

  inputs = {
    # Using the 25.11 stable branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self, 
    nixpkgs, 
    home-manager,
    ... 
    } @ inputs: {
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
  };
}