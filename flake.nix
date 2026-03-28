{
  description = "vimwl: Vim inspired dwl fork";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nvim-nix.url = "github:JacksStuff0905/nvim-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # All build/runtime deps — mirrors what config.mk expects via pkg-config
        buildDeps = with pkgs; [
          wlroots_0_18 # or just `wlroots` — match your target version
          wayland
          wayland-protocols
          wayland-scanner
          libinput
          libxkbcommon
          pixman
          libdrm
          fcft # if you add status bar patches
        ];

        devUtils =
          with pkgs;
          let
            nvim = inputs.nvim-nix.packages."${system}".full;
          in
          [
            nvim
            zsh
            jdk
          ];

        xwaylandDeps = with pkgs; [
          xwayland
          libxcb
          xcbutilwm
          libxcb-wm
        ];

        nativeBuildDeps = with pkgs; [
          pkg-config
          gcc
          gnumake
        ];
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "vimwl";
          version = "0.7-custom";
          src = ./.;

          nativeBuildInputs = nativeBuildDeps;
          buildInputs = buildDeps ++ xwaylandDeps;

          # If you track config.h in git:
          # (otherwise copy config.def.h → config.h in preBuild)
          preBuild = ''
            [ -f config.h ] || cp config.def.h config.h
          '';

          makeFlags = [
            "PREFIX=$(out)"
            "XWAYLAND=-DXWAYLAND" # remove if you don't want Xwayland
          ];

          meta.mainProgram = "dwl";
        };

        devShells.default = pkgs.mkShell {
          name = "vimwl-dev";

          nativeBuildInputs = nativeBuildDeps;
          buildInputs = buildDeps ++ xwaylandDeps ++ devUtils;

          shellHook = ''
            echo "vimwl development env loaded, use 'make' to build"
            exec zsh
          '';
        };
      }
    );
}
