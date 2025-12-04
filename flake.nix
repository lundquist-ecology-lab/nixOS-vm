{
  description = "NixOS VM configuration with AI tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nix-ai-tools.url = "github:numtide/nix-ai-tools";
  };

  outputs = { self, nixpkgs, nix-ai-tools, ... }: {
    nixosConfigurations = {
      nix-python = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
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
        ];
      };

      moria = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
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
        ];
      };
    };
  };
}
