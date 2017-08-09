BUILDROOT_TARGETS   = zlib expat libmad libusb libfuse mpd strace tcpdump tcpreplay openssl curl rsync libupnp libmad

include ../../buildroot.mk

## This package can't be downloaded by buildroot properly
##
PKGCONF_URL	= $(shell cat ../../url-pkgconf)
PKGCONF		= $(shell basename $(PKGCONF_URL))

arch-patches:	.gcc.patch.applied
	@if [ ! -f $(DLDIR)/$(PKGCONF) ]; then wget -O $(DLDIR)/$(PKGCONF) $(PKGCONF_URL); fi
	@diff -qN mod/config build/.config || cp mod/config build/.config
	@diff -qN mod/uClibc-0.9.33.config build/toolchain/uClibc/uClibc-0.9.33.config || cp mod/uClibc-0.9.33.config build/toolchain/uClibc/uClibc-0.9.33.config
	@diff -qN mod/bash.mk build/package/bash/bash.mk || cp mod/bash.mk build/package/bash/bash.mk
	
.gcc.patch.applied:
	tar xf gcc-4.9.3.tar
	touch $@
