PKGTOP	= $(shell cd ../..; pwd)
DLDIR	= $(PKGTOP)/dl

TOPDIR	    = $(shell pwd)
BUILDROOT   = $(shell cd ../buildroot/build; pwd)
TOOLCHAIN   = $(shell cd $(BUILDROOT)/output/host/usr/bin/; pwd)
DESTDIR	    = $(TOPDIR)/output
SYSROOT	    = $(BUILDROOT)/output/host/usr/i686-buildroot-linux-uclibc/sysroot

URL	= $(shell cat $(PKGTOP)/url-mpd)
FILE	= $(DLDIR)/$(shell basename $(URL))

all:	build/config.status
	@make -C build PATH=$(TOOLCHAIN):$(PATH)

$(FILE):
	@cd $(DLDIR); wget $(URL)

build/configure:    $(FILE)
	@mkdir -p build
	@cd build; tar xf $(FILE) --strip-components=1
	@cd build; patch -p1 < ../pipe_volume_ctrl.patch
	cd build; aclocal
	cd build; automake
	cd build; autoreconf
	@touch build/configure

autoconf: 
	cd build; aclocal
	cd build; automake
	cd build; autoreconf

build/config.status:	build/configure
	@cd build; export PATH=$(TOOLCHAIN):$(PATH); ./configure --host=i686-buildroot-linux-uclibc --target=i686-buildroot-linux-uclibc --with-zeroconf=no --disable-oss --disable-alsa --disable-pulse --enable-pipe-output --disable-icu --enable-glib --sysconfdir=/var/tmp --enable-mad --enable-lsr --enable-fifo --enable-flac --disable-mpg123 --enable-recorder-output --enable-sqlite --enable-vorbis --enable-aac --enable-id3 --enable-nfs

clean:
	rm -rf build
