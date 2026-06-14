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

      devShells.${linuxSystem} = {
        ai-trading = let
          pkgs = import nixpkgs {
            system = linuxSystem;
            config = { allowUnfree = true; };
          };
        in pkgs.mkShell {
          name = "ai-trading";

          packages = with pkgs; [
            python312
            python312Packages.pip
            python312Packages.virtualenv
            stdenv.cc.cc.lib  # libstdc++
            zlib
            gcc
            git
          ];

          LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [
            pkgs.stdenv.cc.cc.lib
            pkgs.zlib
          ]}:/run/opengl-driver/lib";

          CUDA_HOME = "/run/opengl-driver";

          shellHook = ''
            VENV_DIR="$HOME/ai-trading-venv"

            if [ ! -d "$VENV_DIR" ]; then
              echo "Creating virtual environment at $VENV_DIR..."
              python3 -m venv "$VENV_DIR"
              echo "Virtual environment created. Run 'ai-trading-setup' to install packages."
            fi

            source "$VENV_DIR/bin/activate"

            echo ""
            echo "=== AI Stock Trading Development Environment ==="
            echo "Python:  $(python --version)"
            echo "Venv:    $VENV_DIR"
            echo "CUDA:    $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo 'not available')"
            echo ""
            echo "Commands:"
            echo "  ai-trading-setup    Install/update all pip packages"
            echo "  ai-trading-verify   Verify GPU and package availability"
            echo "  ai-trading-jupyter  Start Jupyter notebook server"
            echo "  ai-trading-lean     Pull and verify LEAN Docker image"
            echo ""
          '';
        };
      };
    };
}
