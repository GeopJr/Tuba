.PHONY: all install uninstall build test potfiles
PREFIX ?= /usr

clapper ?=
# Remove the devel headerbar style:
# make release=1
release ?=

all: build

build:
	meson setup builddir --prefix=$(PREFIX)
	meson configure builddir -Ddevel=$(if $(release),false,true) -Dclapper=$(if $(clapper),true,false)
	meson compile -C builddir

install:
	meson install -C builddir

uninstall:
	sudo ninja uninstall -C builddir

test:
	ninja test -C builddir

potfiles:
	find ./ -not -path '*/.*' -type f -name "*.in" | sort > po/POTFILES
	echo "" >> po/POTFILES
	find ./ -not -path '*/.*' -type f -name "*.ui" -exec grep -l "translatable=\"yes\"" {} \; | sort >> po/POTFILES
	echo "" >> po/POTFILES
	find ./ -not -path '*/.*' -type f -name "*.vala" -exec grep -l "_(\"\|ngettext" {} \; | sort >> po/POTFILES

windows: PREFIX = $(PWD)/tuba_windows_portable
windows: __windows_pre build install __windows_set_icon __windows_copy_deps __windows_schemas __windows_copy_icons __windows_cleanup __windows_package

__windows_pre:
	rm -rf $(PREFIX)
	mkdir -p $(PREFIX)/lib/

__windows_set_icon:
ifeq (,$(wildcard ./rcedit-x64.exe))
	wget https://github.com/electron/rcedit/releases/download/v1.1.1/rcedit-x64.exe
endif
	rsvg-convert ./data/icons/color-nightly.svg -o ./builddir/color-nightly.png -h 256 -w 256
	magick -density "256x256" -background transparent ./builddir/color-nightly.png -define icon:auto-resize -colors 256 ./builddir/dev.geopjr.Tuba.ico
	./rcedit-x64.exe $(PREFIX)/bin/dev.geopjr.Tuba.exe --set-icon ./builddir/dev.geopjr.Tuba.ico

__windows_copy_deps:
	ldd $(PREFIX)/bin/dev.geopjr.Tuba.exe | grep '\/mingw.*\.dll' -o | xargs -I{} cp "{}" $(PREFIX)/bin
	cp -f /mingw64/bin/gdbus.exe $(PREFIX)/bin && ldd $(PREFIX)/bin/gdbus.exe | grep '\/mingw.*\.dll' -o | xargs -I{} cp "{}" $(PREFIX)/bin
	cp -f /mingw64/bin/gspawn-win64-helper.exe $(PREFIX)/bin && ldd $(PREFIX)/bin/gspawn-win64-helper.exe | grep '\/mingw.*\.dll' -o | xargs -I{} cp "{}" $(PREFIX)/bin
	cp -f /mingw64/bin/libwebp-7.dll /mingw64/bin/librsvg-2-2.dll /mingw64/bin/libgnutls-30.dll /mingw64/bin/libgthread-2.0-0.dll /mingw64/bin/libgmp-10.dll /mingw64/bin/libproxy-1.dll ${PREFIX}/bin
	cp -r /mingw64/lib/gio/ $(PREFIX)/lib
	cp -r /mingw64/lib/gdk-pixbuf-2.0 $(PREFIX)/lib/gdk-pixbuf-2.0
	cp -r /mingw64/lib/gstreamer-1.0 $(PREFIX)/lib/gstreamer-1.0

	cp -f /mingw64/share/gtksourceview-5/styles/Adwaita.xml /mingw64/share/gtksourceview-5/styles/Adwaita-dark.xml ${PREFIX}/share/gtksourceview-5/styles/
	cp -f /mingw64/share/gtksourceview-5/language-specs/xml.lang /mingw64/share/gtksourceview-5/language-specs/markdown.lang /mingw64/share/gtksourceview-5/language-specs/html.lang ${PREFIX}/share/gtksourceview-5/language-specs/

	ldd $(PREFIX)/lib/gio/*/*.dll | grep '\/mingw.*\.dll' -o | xargs -I{} cp "{}" $(PREFIX)/bin
	ldd $(PREFIX)/lib/gstreamer-1.0/*.dll | grep '\/mingw.*\.dll' -o | xargs -I{} cp "{}" $(PREFIX)/bin
	ldd $(PREFIX)/bin/*.dll | grep '\/mingw.*\.dll' -o | xargs -I{} cp "{}" $(PREFIX)/bin

__windows_schemas:
	cp -r /mingw64/share/glib-2.0/schemas/*.xml ${PREFIX}/share/glib-2.0/schemas/
	glib-compile-schemas.exe ${PREFIX}/share/glib-2.0/schemas/

__windows_copy_icons:
	cp -r /mingw64/share/icons/ $(PREFIX)/share/

__windows_cleanup:
	rm -f ${PREFIX}/share/glib-2.0/schemas/*.xml
	rm -rf ${PREFIX}/share/icons/hicolor/scalable/actions/
	find $(PREFIX)/share/icons/ -name *.*.*.svg -not -name *geopjr* -delete
	find $(PREFIX)/lib/gdk-pixbuf-2.0/2.10.0/loaders -name *.a -not -name *geopjr* -delete
	find $(PREFIX)/share/icons/ -name mimetypes -type d  -exec rm -r {} + -depth
	find $(PREFIX)/share/icons/hicolor/ -path */apps/*.png -not -name *geopjr* -delete
	find $(PREFIX) -type d -empty -delete
	gtk-update-icon-cache $(PREFIX)/share/icons/Adwaita/
	gtk-update-icon-cache $(PREFIX)/share/icons/hicolor/

__windows_package:
	zip -r9q tuba_windows_portable.zip tuba_windows_portable/

windows_nsis:
	rm -rf nsis
	mkdir nsis
	cp ./builddir/dev.geopjr.Tuba.ico nsis/
	cp ./builddir/dev.geopjr.Tuba.nsi nsis/
	mv tuba_windows_portable/ nsis/
	cd nsis && makensis dev.geopjr.Tuba.nsi
