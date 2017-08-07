PKGTOP	= $(shell cd ../..; pwd)
DLDIR	= $(PKGTOP)/dl

TOPDIR	    = $(shell pwd)
BUILDROOT   = $(shell cd ../buildroot/build; pwd)
TOOLCHAIN   = $(shell cd $(BUILDROOT)/output/host/usr/bin/; pwd)
DESTDIR	    = $(TOPDIR)/output
SYSROOT	    = $(BUILDROOT)/output/host/usr/i686-buildroot-linux-uclibc/sysroot

URL	= $(shell cat $(PKGTOP)/url-libupnpp)
FILE	= $(DLDIR)/$(shell basename $(URL))

export PATH := $(TOOLCHAIN):$(PATH)

all:	build/config.status
	@make -C build PATH=$(TOOLCHAIN):$(PATH)

$(FILE):
	@cd $(DLDIR); wget $(URL)

build/configure:    $(FILE)
	@mkdir -p build
	@cd build; tar xf $(FILE) --strip-components=1
	@cd build; patch -p1 < ../ff-libupnpp.patch
#	cd build; sh autogen.sh
	@touch build/configure

build/config.status:	build/configure
	@cd build; ./configure --host=i686-buildroot-linux-uclibc --target=i686-buildroot-linux-uclibc prefix=/usr
	@cd build; make install DESTDIR=$(SYSROOT)
	@cd build; make install DESTDIR=$(TOPDIR)/output

install:
	@cp -a output/usr/lib/lib*so* $(DESTDIR)/lib

clean:
	rm -rf build output
