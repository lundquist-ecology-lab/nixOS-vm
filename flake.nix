{
  description = "NixOS VM configuration with AI tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-ai-tools.url = "github:numtide/nix-ai-tools";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nix-ai-tools, home-manager, ... }@inputs:
    let
      linuxSystem = "x86_64-linux";

      unstablePkgs = import nixpkgs-unstable {
        system = linuxSystem;
        config = {
          allowUnfree = true;
        };
      };

      # Overlays for Python version overrides
      pythonOverlays = [
        # Override default Python 3 to use Python 3.13 system-wide (latest stable)
        (final: prev: {
          python3 = prev.python313;
          python3Packages = prev.python313Packages;
        })
      ];
    in
    {
      nixosConfigurations = {
        nix-python = nixpkgs.lib.nixosSystem {
          system = linuxSystem;
          specialArgs = {
            inherit unstablePkgs;
            inherit inputs;
          };
          modules = [
            { nixpkgs.overlays = pythonOverlays; }
            ./configuration.nix
            ({ pkgs, ... }: {
              environment.systemPackages = with nix-ai-tools.packages.${pkgs.system}; [
                claude-code
                opencode
                crush
                gemini-cli
                codex
              ];
            })
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = {
                inherit unstablePkgs;
                inherit inputs;
                hostname = "nix-python";
              };
              home-manager.users.mlundquist = import ./home.nix;
            }
          ];
        };

        moria = nixpkgs.lib.nixosSystem {
          system = linuxSystem;
          specialArgs = {
            inherit unstablePkgs;
            inherit inputs;
          };
          modules = [
            { nixpkgs.overlays = pythonOverlays; }
            ./configuration.nix
            ({ pkgs, ... }: {
              environment.systemPackages = with nix-ai-tools.packages.${pkgs.system}; [
                claude-code
                opencode
                crush
                gemini-cli
                codex
              ];
            })
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = {
                inherit unstablePkgs;
                inherit inputs;
                hostname = "moria";
              };
              home-manager.users.mlundquist = import ./home.nix;
            }
          ];
        };
      };
    };
}
