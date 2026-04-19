{

  description = "A personal knowledge base system for neovim with journal-based note-taking";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    dave-shield.url = "github:dczmer/dave-shield";
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
      dave-shield,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
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
          git
          lua54Packages.luacheck
          lua-language-server
          stylua
          gh
          mdl
          tree
        ];
        neovimWrapped = pkgs.wrapNeovim pkgs.neovim-unwrapped {
          configure = {
            inherit customRC;
            packages.myVimPackage = with pkgs.vimPlugins; {
              start = [
                nvim-cmp
                cmp-buffer
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
        extraPkgs = [
          nvim-test-app
        ]
        ++ runtimeInputs
        ++ devPackages;
        extraCombinators = [
        ];
        daveShield = dave-shield.lib.${system}.daveShield;
        makeJailedOpenCode = dave-shield.lib.${system}.makeJailedOpenCode;
      in
      rec {
        packages = {
          jailedOpenCode = makeJailedOpenCode {
            inherit extraPkgs extraCombinators;
          };
          jailedShell = daveShield {
            exec = pkgs.bash;
            inherit extraPkgs extraCombinators;
          };
        };
        apps = rec {
          default = nvim-test;
          nvim-test = {
            type = "app";
            program = "${nvim-test-app}/bin/nvim-test";
          };
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [
            packages.jailedOpenCode
            packages.jailedShell
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
