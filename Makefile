
TOPDIR	= $(shell pwd)
VERSION = $(shell cat version)
APP_VER = $(shell cat packages/x86/ffritz/version)
ARM_VER = $(shell cat packages/arm/ffritz/version)
REL_VER = $(shell date +%Y%m%d-%H%M)
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
#ORIG=$(TOPDIR)/../FRITZ.Box_6490_Cable.de-en-es-it-fr-pl.141.06.63.image
ORIG=$(TOPDIR)/../FRITZ.Box_6490_Cable.de-en-es-it-fr-pl.141.06.83.image

# Keep original rootfs for diff?
# sudo dirdiff arm/orig/ arm/squashfs-root/
#
KEEP_ORIG = 1

# The optional arm package contains some binaries which may as well be installed to
# to the ftp directory (-> /var/media/ftp/ffritz-arm)
# To build: "make arm-package"
#
FFRITZ_ARM_PACKAGE=../ffritz-arm-0.4.tar.gz


## Host tools (unsquashfs4-lzma-avm-be, mksquashfs4-lzma-avm-be) can either be built
# (using squashfstools-be target), or try the pre-compiled binaries
#
#HOSTTOOLS=$(TOPDIR)/freetz/tools
HOSTTOOLS=$(TOPDIR)/host/$(HOST)

###############################################################################################

RELDIR  = release$(VERSION)

ARM_MODFILES = $(shell find arm/mod/ -type f -o -type d)
ATOM_MODFILES = $(shell find atom/mod/ -type f -o -type d)

###############################################################################################
###############################################################################################
FWVER=$(shell strings $(ORIG) | grep -i ^newFWver=|sed -e 's/.*=//')
FWNUM=$(subst .,,$(FWVER))

ifeq ($(FWVER),)
$(error Could not determine firmware version ($(ORIG) missing?))
endif

ifeq ($(PKGMAKE),1)
FFRITZ_ARM_PACKAGE=packages/arm/ffritz/ffritz-arm-$(ARM_VER).tar.gz
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

all: release

###############################################################################################
## Unpack, patch and repack ARM FS
#
armfs:	arm/filesystem.image

ARM_PATCHES += rc.tail.patch
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

arm/.applied.fs: $(ARM_MODFILES) arm/squashfs-root $(ARM_PATCHST) $(FFRITZ_ARM_PACKAGE)
	@echo "PATCH  arm/squashfs-root"
	@$(SUDO) rm -rf arm/squashfs-root/usr/local
	@$(SUDO) $(RSYNC) -a --no-perms arm/mod/ arm/squashfs-root/
	@if [ -f "$(FFRITZ_ARM_PACKAGE)" ]; then \
	    echo Integrating ARM extensions from $(FFRITZ_ARM_PACKAGE); \
	    $(SUDO) mkdir -p arm/squashfs-root/usr/local; \
	    $(SUDO) tar xfk $(FFRITZ_ARM_PACKAGE) --strip-components=2 -C arm/squashfs-root/usr/local ./ffritz-arm; \
	fi
	$(TOPDIR)/mklinks arm/squashfs-root/usr/bin ../local/bin $(SUDO); 
	@touch $@

arm/filesystem.image: arm/.applied.fs
	@rm -f arm/filesystem.image
	@echo "PACK  arm/squashfs-root"
	@cd arm; $(SUDO) $(HOSTTOOLS)/mksquashfs4-lzma-avm-be squashfs-root filesystem.image -all-root -info -no-progress -no-exports -no-sparse -b 65536 >/dev/null

ifneq ($(FFRITZ_ARM_PACKAGE),)
ifeq ($(PKGMAKE),)
$(FFRITZ_ARM_PACKAGE):
	@echo Please download $(FFRITZ_ARM_PACKAGE) from https://bitbucket.org/fesc2000/ffritz/downloads
	@echo "(or try to build it with \"make arm-package\")"
	@echo
	endif
endif
endif

arm-package: packages/arm/ffritz/ffritz-arm-$(ARM_VER).tar.gz

packages/arm/ffritz/ffritz-arm-$(ARM_VER).tar.gz:
	make -C packages/arm/ffritz
	@echo
	@echo Successfully built $@

###############################################################################################
## Unpack, patch and repack ATOM FS 
#
atomfs:	atom/filesystem.image

ATOM_PATCHES = 50-udev-default.patch profile.patch

ATOM_PATCHST=$(ATOM_PATCHES:%=atom/.applied.%)

tmp/atom/filesystem.image:
	@mkdir -p tmp/atom
	@cd tmp/atom; tar xf $(ORIG) ./var/remote/var/tmp/x86/filesystem.image --strip-components=6

atom/squashfs-root:  tmp/atom/filesystem.image
	@if [ ! -d atom/squashfs-root ]; then cd atom; $(SUDO) unsquashfs $(TOPDIR)/tmp/atom/filesystem.image; fi
	@if [ $(KEEP_ORIG) -eq 1 -a ! -d atom/orig ]; then cd atom; $(SUDO) unsquashfs -d orig $(TOPDIR)/tmp/atom/filesystem.image; fi
	@$(SUDO) chmod 755 atom/squashfs-root

$(ATOM_PATCHST):	$(@:atom/.applied.%=%)
	@echo APPLY $(@:atom/.applied.%=%)
	@cd atom/squashfs-root; $(SUDO) patch -p1 < $(@:atom/.applied.%=../%)
	@touch $@

atom/.applied.fs: $(ATOM_MODFILES) atom/squashfs-root $(ATOM_PATCHST)
	@echo "PATCH  atom/squashfs-root"
	@$(SUDO) $(RSYNC) -a atom/mod/ atom/squashfs-root/
	@mkdir -p atom/squashfs-root/usr/local
	@touch $@

atom/filesystem.image: atom/.applied.fs
	@rm -f atom/filesystem.image
	@echo "CHMOD  atom/squashfs-root"
	@$(SUDO) chmod 600 atom/squashfs-root
	@echo "PACK  atom/squashfs-root"
	@cd atom; $(SUDO) mksquashfs squashfs-root filesystem.image -all-root -info -no-progress -no-exports -no-sparse -b 65536 >/dev/null

#.PHONY:		$(RELDIR)

app-package: packages/x86/ffritz/ffritz-app-$(APP_VER).tar

packages/x86/ffritz/ffritz-app-$(APP_VER).tar:
	make -C packages/x86/ffritz |& colorize
	@cp $@ $(RELDIR)/ffritz-app-$(APP_VER)_$(REL_VER).tar
	@echo
	@echo -e Successfully built $(RELDIR)/ffritz-app-$(APP_VER)_$(REL_VER).tar [`cat packages/x86/ffritz/ffimage.sha256sum`]

###############################################################################################
release:    $(RELDIR)/fb6490_$(FWVER)-$(VERSION)_$(REL_VER).tar

$(RELDIR)/fb6490_$(FWVER)-$(VERSION)_$(REL_VER).tar: armfs atomfs $(RELDIR)
	@rm -rf $(RELDIR)/var
	@cd $(RELDIR); tar xf $(ORIG)
	@echo "PACK   $(RELDIR)/fb6490_$(FWVER)-$(VERSION)_$(REL_VER).tar"
	@cp arm/filesystem.image $(RELDIR)/var/remote/var/tmp/filesystem.image
	@cp arm/mod/usr/local/etc/switch_bootbank $(RELDIR)/var
	@cp atom/filesystem.image $(RELDIR)/var/remote/var/tmp/x86/filesystem.image
	@cd $(RELDIR); $(TAR) cf fb6490_$(FWVER)-$(VERSION)_$(REL_VER).tar var
	@rm -rf $(RELDIR)/var

$(RELDIR):
	@echo "PREP   $(RELDIR)"
	@mkdir -p $(RELDIR)

###############################################################################################
#
# In case the packaged squashfs tools do not work ..
#

freetz:
	git clone https://github.com/Freetz/freetz.git

squashfstools-be:	freetz
	make -C freetz tools/mksquashfs4-lzma-avm-be tools/unsquashfs4-lzma-avm-be


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
