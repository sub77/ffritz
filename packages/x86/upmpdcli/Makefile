PKGTOP	= $(shell cd ../..; pwd)
DLDIR	= $(PKGTOP)/dl

TOPDIR	    = $(shell pwd)
BUILDROOT   = $(shell cd ../buildroot/build; pwd)
TOOLCHAIN   = $(shell cd $(BUILDROOT)/output/host/usr/bin/; pwd)
DESTDIR	    = $(TOPDIR)/output
SYSROOT	    = $(BUILDROOT)/output/host/usr/i686-buildroot-linux-uclibc/sysroot
FFHOME	    = /var/media/ftp/ffritz

BFILE = ./build/upmpdcli
DFILE1 = $(TOPDIR)/output/usr/bin/upmpdcli
DFILE2 = $(DESTDIR)/bin/upmpdcli

URL	= $(shell cat $(PKGTOP)/url-upmpdcli)
FILE	= $(DLDIR)/$(shell basename $(URL))

export PATH := $(TOOLCHAIN):$(PATH)

all:	build/config.status
	@make -C build PATH=$(TOOLCHAIN):$(PATH)

$(FILE):
	@cd $(DLDIR); wget $(URL)

build/configure:    $(FILE)
	@mkdir -p build
	@cd build; tar xf $(FILE) --strip-components=1
#	@cd build; patch -p1 < ../ff-libupnpp.patch
#	cd build; sh autogen.sh
	@touch build/configure

build/config.status:	build/configure
	@cd build; ./configure --host=i686-buildroot-linux-uclibc --target=i686-buildroot-linux-uclibc prefix=/usr --datarootdir=$(FFHOME)/share --sysconfdir=$(FFHOME)/etc

install:	$(DFILE2)

$(DFILE2):	$(DFILE1)
	@mkdir -p $(DESTDIR)/bin $(DESTDIR)/share/upmpdcli/cdplugins $(DESTDIR)/etc
	@cp -f output/usr/bin/* $(DESTDIR)/bin
	@for f in output/var/media/ftp/ffritz/share/upmpdcli/*; do test -f $$f && cp -f $$f $(DESTDIR)/share/upmpdcli; done; true

$(DFILE1):	$(BFILE)
	@cd build; make install DESTDIR=$(TOPDIR)/output
	
clean:
	rm -rf build output
