{
  description = "slock";

  # Nixpkgs / NixOS version to use.
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixvim.url = "github:hellopoisonx/nixvim";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixvim,
      ...
    }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      nixpkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        }
      );
    in
    {

      # A Nixpkgs overlay.
      overlay = final: prev: {
        slock = final.stdenv.mkDerivation {
          pname = "slock";
          inherit version;

          src = ./.;
          buildInputs = with final; [
            xorg.libX11
            xorg.libXft
            xorg.libXrandr
            xorg.libXext
            imlib2
            libxcrypt
          ];
          nativeBuildInputs = with final; [
            pkg-config
            makeWrapper
            nixvim.packages.${final.system}.c-cpp
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

      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) slock;
      });
      defaultPackage = forAllSystems (system: self.packages.${system}.slock);
    };
}
