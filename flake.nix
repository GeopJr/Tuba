{
  description = "Browse the Fediverse";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/master";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { system = system; };

      nativeBuildInputs = with pkgs; [
        meson
        ninja
        vala
        pkg-config
        desktop-file-utils
        python39
        gtk3
        wrapGAppsHook
      ];

      buildInputs = with pkgs; [
        meson
        ninja
        vala
        glib
        gtk4
        json-glib
        libxml2
        libgee
        libsoup
        libadwaita
        libsecret
      ];
    in
    {
      devShells = {
        ${system} = {
          default = pkgs.mkShell {
            packages = buildInputs ++ nativeBuildInputs;
          };
        };
      };

      packages = {
        ${system} = {
          tooth =
            pkgs.stdenv.mkDerivation {
              name = "tooth";
              src = self;

              nativeBuildInputs = nativeBuildInputs;
              buildInputs = buildInputs;

              preFixup = with pkgs; ''
                gappsWrapperArgs+=(
                  --prefix XDG_DATA_DIRS : "$XDG_ICON_DIRS" \
                  --prefix XDG_DATA_DIRS : "$out/share" \
                  --prefix XDG_DATA_DIRS : "$out/share/gsettings-schemas/dev.geopjr.Tooth" \
                  --prefix XDG_DATA_DIRS : "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}" \
                  --prefix XDG_DATA_DIRS : "${hicolor-icon-theme}/share" \
                  --prefix GI_TYPELIB_PATH : "${lib.makeSearchPath "lib/girepository-1.0" [ pango json-glib ]}"
                )
              '';

              configurePhase = "meson build --prefix=$out";

              buildPhase = "ninja -C build";
              installPhase = "
                patchShebangs meson/post_install.py
                ninja -C build install
              ";

              postInstallPhase = "
                meson/post_install.py
              ";
            };

          default = self.packages.${system}.tooth;
        };
      };


    };
}
