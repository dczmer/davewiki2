{
  description = "A personal knowledge base system for neovim with journal-based note-taking";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = {
          nvim-test = pkgs.writeScriptBin "nvim-test" ''
            #!${pkgs.bash}/bin/bash
            exec ${pkgs.neovim-unwrapped}/bin/nvim -u scripts/minimal-init.lua "$@"
          '';

          davewiki = pkgs.writeScriptBin "davewiki" ''
            #!${pkgs.bash}/bin/bash
            exec ${pkgs.neovim-unwrapped}/bin/nvim -u scripts/minimal-init.lua "$@"
          '';

          luacheck = pkgs.luacheck;

          stylua = pkgs.stylua;

          lua-language-server = pkgs.lua-language-server;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            neovim-unwrapped
            lua-language-server
            luacheck
            stylua
            git
            ripgrep
            fd
          ];

          shellHook = ''
            echo "Development environment for davewiki loaded"
            echo "Run 'nix develop' to enter the dev shell"
            echo "Use 'nix run .#nvim-test -- -u scripts/minimal-init.lua --headless -c \"lua ...\"' to run tests"
          '';
        };
      }
    );
}
