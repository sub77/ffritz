
TOPDIR	= $(shell pwd)
VERSION = $(shell cat version)
HOST    = $(shell uname -m)
SUDO	= sudo

###############################################################################################
# Configuration
###############################################################################################
#
# The original firmware tarball
#
#ORIG=$(TOPDIR)/../original_141.06.50.tar
#ORIG=$(TOPDIR)/../FRITZ.Box_6490_Cable.de-en-es-it-fr-pl.141.06.61.image
#ORIG=$(TOPDIR)/../FRITZ.Box_6490_Cable.de-en-es-it-fr-pl.141.06.62.image
ORIG=$(TOPDIR)/../FRITZ.Box_6490_Cable.de-en-es-it-fr-pl.141.06.63.image

# Keep original rootfs for diff?
# sudo dirdiff arm/orig/ arm/squashfs-root/
#
KEEP_ORIG = 1

# UNCOMMENT THIS if you want to modify the Atom core filesystem, adding
# stuff from the x86/ffritz package (dropbear, mpd, shairport, tools).
# To keep the atom FS unmodified, comment this out.
#
# Otherwise the ffritz-x86 package can be installed to the ftp directory, which is more 
# flexible but unsafe.
#
# The package can be either downloaded (https://bitbucket.org/fesc2000/ffritz/downloads),
# or built with "make package"
#
#FFRITZ_X86_PACKAGE=../ffritz-x86-0.4.tar.gz

###############################################################################################

RELDIR  = release$(VERSION)

ARM_MODFILES = $(shell find arm/mod/ -type f -o -type d)
ATOM_MODFILES = $(shell find atom/mod/ -type f -o -type d)

HOSTTOOLS=$(TOPDIR)/host/$(HOST)

###############################################################################################
###############################################################################################

FWVER=$(shell strings $(ORIG) | grep -i ^newFWver=|sed -e 's/.*=//')
FWNUM=$(subst .,,$(FWVER))

ifeq ($(FWVER),)
$(error Could not determine firmware version ($(ORIG) missing?))
endif

BUSYBOX	= $(shell which busybox)
RSYNC	= $(shell which rsync)

ifeq ($(BUSYBOX),)
$(warning using tar to pack archive, recommend to install busybox)
TAR	= tar
else
TAR	= busybox tar
endif

ifeq ($(RSYNC),)
$(error rsync missing, please install)
endif

ifneq ($(FFRITZ_X86_PACKAGE),)
    ATOMFS=atomfs
endif

all: release

###############################################################################################
## Unpack, patch and repack ARM FS
#
armfs:	arm/filesystem.image

ARM_PATCHES  = rc.tail.patch
ARM_PATCHES += $(shell test $(FWNUM) -gt 660 && echo nvram_dontremove.patch)
ARM_PATCHES += $(shell test $(FWNUM) -lt 663 && echo ipv6_enable.patch)

ARM_PATCHST=$(ARM_PATCHES:%=arm/.applied.%)

tmp/arm/filesystem.image:
	@mkdir -p tmp/arm
	@cd tmp/arm; tar xf $(ORIG) ./var/remote/var/tmp/filesystem.image --strip-components=5

arm/squashfs-root:  tmp/arm/filesystem.image 
	@if [ ! -d arm/squashfs-root ]; then cd arm; $(SUDO) $(HOSTTOOLS)/unsquashfs4-lzma-avm-be $(TOPDIR)/tmp/arm/filesystem.image; fi
	@if [ $(KEEP_ORIG) -eq 1 -a ! -d arm/orig ]; then cd arm; $(SUDO) $(HOSTTOOLS)/unsquashfs4-lzma-avm-be -d orig $(TOPDIR)/tmp/arm/filesystem.image; fi
	@$(SUDO) chmod 755 arm/squashfs-root

$(ARM_PATCHST):	$(@:arm/.applied.%=%)
	@echo APPLY $(@:arm/.applied.%=%)
	@cd arm/squashfs-root; $(SUDO) patch -p1 < $(@:arm/.applied.%=../%)
	@touch $@

arm/filesystem.image: $(ARM_MODFILES) arm/squashfs-root $(ARM_PATCHST)
	@echo "PATCH  arm/squashfs-root"
	@$(SUDO) $(RSYNC) -a arm/mod/ arm/squashfs-root/
	@rm -f arm/filesystem.image
	@echo "PACK  arm/squashfs-root"
	@cd arm; $(SUDO) $(HOSTTOOLS)/mksquashfs4-lzma-avm-be squashfs-root filesystem.image -all-root -info -no-progress -no-exports -no-sparse -b 65536 >/dev/null

###############################################################################################
## Unpack, patch and repack ATOM FS 
#
atomfs:	atom/filesystem.image

tmp/atom/filesystem.image:
	@mkdir -p tmp/atom
	@cd tmp/atom; tar xf $(ORIG) ./var/remote/var/tmp/x86/filesystem.image --strip-components=6

atom/squashfs-root:  tmp/atom/filesystem.image
	@if [ ! -d atom/squashfs-root ]; then cd atom; $(SUDO) unsquashfs $(TOPDIR)/tmp/atom/filesystem.image; fi
	@if [ $(KEEP_ORIG) -eq 1 -a ! -d atom/orig ]; then cd atom; $(SUDO) unsquashfs -d orig $(TOPDIR)/tmp/atom/filesystem.image; fi

atom/filesystem.image: $(ATOM_MODFILES) atom/squashfs-root $(FFRITZ_X86_PACKAGE)
	@echo "PATCH  atom/squashfs-root"
	@$(SUDO) $(RSYNC) -a atom/mod/ atom/squashfs-root/
	@test -f $(FFRITZ_X86_PACKAGE) && sudo mkdir -p atom/squashfs-root/usr/local
	@test -f $(FFRITZ_X86_PACKAGE) && sudo tar xf $(FFRITZ_X86_PACKAGE) --strip-components=2 -C atom/squashfs-root/usr/local ./ffritz
	@test -f $(FFRITZ_X86_PACKAGE) && sudo sh -c "cd atom/squashfs-root/usr/bin; ln -sf ../local/bin/* ."
	@rm -f atom/filesystem.image
	@echo "PACK  atom/squashfs-root"
	@cd atom; $(SUDO) mksquashfs squashfs-root filesystem.image -all-root -info -no-progress -no-exports -no-sparse -b 65536 >/dev/null

## Normally the package should be pre-compiled. If not, try to rebuild it
#
ifneq ($(FFRITZ_X86_PACKAGE),)
$(FFRITZ_X86_PACKAGE):
	@echo Please download $(FFRITZ_X86_PACKAGE) from https://bitbucket.org/fesc2000/ffritz/downloads
	@echo "(or try to build it with \"make package\")"
	@echo

package:
	make -C packages/x86/ffritz; cp packages/x86/ffritz/$(shell basename $(FFRITZ_X86_PACKAGE)) $(FFRITZ_X86_PACKAGE)
endif

.PHONY:		$(RELDIR)

###############################################################################################
release:	armfs $(ATOMFS) $(RELDIR) 
	@echo "PACK   $(RELDIR)/fb6490_$(FWVER)-$(VERSION).tar"
	@cp arm/filesystem.image $(RELDIR)/var/remote/var/tmp/filesystem.image
	@cp arm/mod/usr/local/etc/switch_bootbank $(RELDIR)/var
	@test -z $(ATOMFS) || cp atom/filesystem.image $(RELDIR)/var/remote/var/tmp/x86/filesystem.image
	@cd $(RELDIR); $(TAR) cf fb6490_$(FWVER)-$(VERSION).tar var
	@rm -rf $(RELDIR)/var

$(RELDIR):
	@echo "PREP   $(RELDIR)"
	@mkdir -p $(RELDIR)
	@cd $(RELDIR); ln -sf ../README.txt .
	@cd $(RELDIR); ln -sf ../INSTALL.txt .
	@cd $(RELDIR); ln -sf ../telnet-1.tar .
	@cd $(RELDIR); tar xf $(ORIG)

###############################################################################################
clean:
	rm -rf tmp
	$(SUDO) rm -rf arm/squashfs-root
	$(SUDO) rm -rf arm/orig
	rm -f arm/filesystem.image
	rm -f arm/.applied*
	$(SUDO) rm -rf atom/squashfs-root
	$(SUDO) rm -rf atom/orig
	rm -f atom/filesystem.image
	rm -f atom/.applied*
	rm -f .fwver.cache
