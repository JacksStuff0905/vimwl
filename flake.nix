{
  description = "vimwl: Vim inspired dwl fork";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # All build/runtime deps — mirrors what config.mk expects via pkg-config
        buildDeps = with pkgs; [
          wlroots_0_18      # or just `wlroots` — match your target version
          wayland
          wayland-protocols
          wayland-scanner
          libinput
          libxkbcommon
          pixman
          libdrm
          fcft               # if you add status bar patches
        ];

        xwaylandDeps = with pkgs; [
          xwayland
          libxcb
          xcbutilwm
          xorg.xcbutilwm
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
            "XWAYLAND=-DXWAYLAND"   # remove if you don't want Xwayland
          ];

          meta.mainProgram = "dwl";
        };

        devShells.default = pkgs.mkShell {
          name = "vimwl-dev";

          nativeBuildInputs = nativeBuildDeps;
          buildInputs = buildDeps ++ xwaylandDeps;

          # Nix-specific: help pkg-config and the compiler find headers/libs
          shellHook = ''
            echo "vimwl dev shell ready — just run 'make'"
          '';
        };
      }
    );
}
