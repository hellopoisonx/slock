{
  description = "slock";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim.url = "github:hellopoisonx/nixvim";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          self',
          inputs',
          pkgs,
          ...
        }:
        let
          lastModifiedDate = self'.lastModifiedDate or self'.lastModified or "19700101";
          version = builtins.substring 0 8 lastModifiedDate;
        in
        {
          packages.slock =
            with pkgs;
            stdenv.mkDerivation {
              pname = "slock";
              inherit version;

              src = ./.;
              buildInputs = [
                xorg.libX11
                xorg.libXft
                xorg.libXrandr
                xorg.libXext
                imlib2
                libxcrypt
              ];
              nativeBuildInputs = [
                pkg-config
                makeWrapper
                inputs'.nixvim.packages.c-cpp
                bear
              ];
              preConfigure = ''
                sed -i "s@/usr/local@$out@" config.mk
                sed -i "/chmod u+s/d" Makefile
                makeFlagsArray+=(
                  CC="$CC"
                  INCS="`$PKG_CONFIG --cflags x11`"
                  LIBS="`$PKG_CONFIG --libs x11 xft xrender libcrypt xext imlib2`"
                )
              '';
              buildPhase = ''
                make clean
                make all
              '';
              installPhase = ''
                make clean install
              '';
            };
          packages.default = self'.packages.slock;
        };
    };
}
