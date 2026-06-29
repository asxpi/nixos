{
  description = "NixOS configuration with Lanzaboote";

  inputs = {
    lanzaboote = {
      url = "github:nix-community/lanzaboote/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    anotherim = {
      url = "git+https://dev.narayana.im/anotherim/anotherim-desktop.git?ref=dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.meow = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.sops-nix.nixosModules.sops
        inputs.nix-flatpak.nixosModules.nix-flatpak
        ./configuration.nix
      ];
    };
  };
}
