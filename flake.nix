{
  description = "A personal knowledge base system for neovim with journal-based note-taking";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        customRC = ''
          " manually add each plugin dependency to rtp so we can load them from plenary tests.
          set rtp+=${pkgs.vimPlugins.nvim-cmp}
          set rtp+=${pkgs.vimPlugins.telescope-nvim}
          set rtp+=${pkgs.vimPlugins.telescope-fzf-native-nvim}
          set rtp+=${pkgs.vimPlugins.which-key-nvim}
        '';
        runtimeInputs = with pkgs; [
          ripgrep
          fd
          fzf
        ];
        devPackages = with pkgs; [
          lua54Packages.luacheck
          lua-language-server
          stylua
          gh
        ];
        neovimWrapped = pkgs.wrapNeovim pkgs.neovim-unwrapped {
          configure = {
            inherit customRC;
            packages.myVimPackage = with pkgs.vimPlugins; {
              start = [
                nvim-cmp
                cmp-buffer
                cmp-path
                cmp-nvim-lsp
                cmp-nvim-lsp-signature-help
                telescope-nvim
                telescope-fzf-native-nvim
                vim-markdown
                which-key-nvim
                plenary-nvim
              ];
            };
          };
        };
        nvim-test-app = pkgs.writeShellApplication {
          name = "nvim-test";
          text = ''
            ${neovimWrapped}/bin/nvim "$@"
          '';
          inherit runtimeInputs;
        };
      in
      {
        packages = {
          ripgrep = pkgs.ripgrep;
          luacheck = pkgs.lua54Packages.luacheck;
          stylua = pkgs.stylua;
          lua-language-server = pkgs.lua-language-server;
          lua = pkgs.lua54Packages.lua;
          gh = pkgs.gh;
        };
        apps = rec {
          default = nvim-test;
          nvim-test = {
            type = "app";
            program = "${nvim-test-app}/bin/nvim-test";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs =
            with pkgs;
            [
              git
            ]
            ++ runtimeInputs
            ++ devPackages;

          shellHook = ''
            echo "Development environment for davewiki loaded"
            echo "Run 'nix develop' to enter the dev shell"
            echo "Use 'nix run .#nvim-test -- -u scripts/minimal-init.lua --headless -c \"lua ...\"' to run tests"
          '';
        };
      }
    );
}
