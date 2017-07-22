PKGTOP	= $(shell cd ../..; pwd)
DLDIR	= $(PKGTOP)/dl

ifeq ($(BUILDROOT),)
BUILDROOT=$(shell cd ../buildroot/build/; pwd)
endif

TOPDIR	    = $(shell pwd)
TOOLCHAIN   = $(shell cd $(BUILDROOT)/output/host/usr/bin/; pwd)

ifeq ($(DESTDIR),)
    DESTDIR	    = $(TOPDIR)/output
endif

export PATH := $(TOOLCHAIN):$(PATH)

URL	= $(shell cat $(PKGTOP)/url-nano)
FILE	= $(DLDIR)/$(shell basename $(URL))

all:	build/config.status
	@make -C build 

install:
	@make -C build install DESTDIR=$(DESTDIR)

$(FILE):
	@cd $(DLDIR); wget $(URL)

build/configure:    $(FILE)
	@mkdir -p build
	@cd build; tar xf $(FILE) --strip-components=1
	@touch build/configure

build/config.status:	build/configure
	@cd build; ./configure --host=i686-buildroot-linux-uclibc

clean:
	rm -rf build

distclean:
	rm -rf build
	rm -f $(FILE)
