{
  description = "NixOS configuration with latest Claude Code & Lanzaboot";

  inputs = {
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, claude-code-nix, ... }@inputs: {
    nixosConfigurations.meow = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        inputs.lanzaboote.nixosModules.lanzaboote
        ./configuration.nix
        ({ pkgs, inputs, ... }: {
          environment.systemPackages = [
            inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
        })
      ];
    };
  };
}
