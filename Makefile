.PHONY: all install uninstall build test potfiles
PREFIX ?= /usr

# Remove the devel headerbar style:
# make release=1
release ?= 

all: build

build:
	meson setup builddir --prefix=$(PREFIX)
	meson configure builddir -Ddevel=$(if $(release),false,true)
	meson compile -C builddir

install:
	meson install -C builddir

uninstall:
	sudo ninja uninstall -C builddir

test:
	ninja test -C builddir

potfiles:
	find ./ -type f -name "*.in" | sort > po/POTFILES
	echo "" >> po/POTFILES
	find ./ -type f -name "*.ui" -exec grep -l "translatable=\"yes\"" {} \; | sort >> po/POTFILES
	echo "" >> po/POTFILES
	find ./ -type f -name "*.vala" -exec grep -l "_(\"" {} \; | sort >> po/POTFILES
