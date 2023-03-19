.PHONY: all install uninstall build
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