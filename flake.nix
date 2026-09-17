# nebula-nix — flake NixOS minimale per nebula (Dell Optiplex 3050)
# Repo dedicato a nebula: layout hosts/nebula + modules + secrets + k8s/
{
  description = "nebula — NixOS baremetal (k3s + Technitium + Flux GitOps)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, sops-nix, disko, impermanence, ... }: {
    nixosConfigurations.nebula = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
      };
      modules = [
        ./hosts/nebula
        sops-nix.nixosModules.sops
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
      ];
    };
  };
}
