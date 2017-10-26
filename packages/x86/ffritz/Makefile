# This makefile either generates a tarball which is supposed to
# ccontain binaries run in /var/media/ftp/ffritz, or
# copies files into a root fs image where they are installed
# to and executed from /usr/local.
#
# For the first, just call make
#
TOPDIR	    = $(shell pwd)
PKGDIR	    = $(shell cd ..; pwd)

BR_TGT	    = ../buildroot/build/output/target
BR_TGT_LIB  = $(BR_TGT)/usr/lib
BR_TGT_BIN  = $(BR_TGT)/usr/bin
BR_TGT_SBIN = $(BR_TGT)/usr/sbin

BINFILES    = ../mpd/build/src/mpd src/sndlist src/usbplay src/usbplayd src/ffdaemon
BINFILES   += $(BR_TGT_BIN)/strace $(BR_TGT_BIN)/ldd $(BR_TGT_SBIN)/tcpdump 
BINFILES   += $(BR_TGT_BIN)/tcpbridge $(BR_TGT_BIN)/tcpprep $(BR_TGT_BIN)/tcpreplay $(BR_TGT_BIN)/tcpreplay-edit $(BR_TGT_BIN)/tcprewrite
BINFILES   += $(BR_TGT_BIN)/mpc $(BR_TGT_BIN)/rsync $(BR_TGT_BIN)/socat  $(BR_TGT_BIN)/nano
BINFILES   += $(BR_TGT)/../host/usr/i686-buildroot-linux-uclibc/sysroot/usr/bin/curl
BINFILES   += $(BR_TGT)/sbin/iwconfig
BINFILES   += $(BR_TGT_SBIN)/openvpn $(BR_TGT_SBIN)/iw $(BR_TGT_SBIN)/dnsmasq
BINFILES   += ../shairport/build/shairport
ETCFILES    = etc/ffritz-env.sh etc/mpd.conf etc/runmpd etc/ff_atom_startup etc/ffservices etc/run_usbplay etc/run_shairport etc/mkusers
ETCFILES   += etc/run_lircd etc/lirc_options_dfl.conf etc/upmpdcli.conf-dist etc/run_bluetooth
ETCFILES   += etc/run_openvpn etc/usrmount etc/run_dnsmasq etc/dnsmasq_dfl.conf
MODFILES    = lib/modules/cdc-acm.ko

STAGEDIR    = $(TOPDIR)/output/ffritz

VERSION     = $(shell cat version)

IMAGE       = ffritz-app-$(VERSION).tar

ifeq ($(INSTDIR),)
    INSTDIR=$(STAGEDIR)
endif

SUBDIRS	    = ../buildroot ../libmaru ../shairport ../libmpdclient ../mpc ../lirc ../libupnpp ../jsoncpp ../upmpdcli ../libnfs ../nfs ../mpd ../bt src
INSTDIRS    = ../lirc/install ../libupnpp/install ../upmpdcli/install ../nfs/install ../bt/install

.PHONY:	$(SUBDIRS) $(IMAGE)

all:	$(SUBDIRS) $(IMAGE)

$(SUBDIRS):	
	mkdir -p ../../dl
	make -C $@

$(INSTDIRS):
	make -C `dirname $@` install DESTDIR=$(INSTDIR)

$(IMAGE): ffimage.bin
	sha256sum ffimage.bin | sed -e 's/ .*//' > ffimage.sha256sum
	cp ../../../*.md .
	tar cf $(IMAGE) ffimage.bin ffimage.sha256sum *.md

ffimage.bin: $(BINFILES) $(ETCFILES) $(shell test -d $(BR_TGT_LIB) && ls $(BR_TGT_LIB)/lib*so*)
	rm -rf $(STAGEDIR)
	make install INSTDIR=$(STAGEDIR)
	rm -f $@
	cd output; mksquashfs ffritz ../$@ -all-root -no-progress -no-exports -no-sparse -b 65536 

# Install everything to target
# LD_LIBRARY_PATH needs to be set correctly for binaries. This is done by the ffwrap wrapper script,
# which is linked to for each binary. This makes the package position independent, i.e.
# it can be installed to /var/media/ftp, or integrated into the atom squashfs (to /usr/local).
#
install: $(BINFILES) $(ETCFILES) $(INSTDIRS) $(shell test -d $(BR_TGT_LIB) && ls $(BR_TGT_LIB)/lib*so*)
	mkdir -p $(INSTDIR)/bin/exec
	mkdir -p $(INSTDIR)/lib/modules
	mkdir -p $(INSTDIR)/etc
	cp -r $(BR_TGT)/usr/share/terminfo $(INSTDIR)/usr/share/terminfo
	cp -a $(BINFILES) $(INSTDIR)/bin
	cp -a $(MODFILES) $(INSTDIR)/lib/modules
	cp -a  $(shell ls  $(BR_TGT_LIB)/lib*so*) $(INSTDIR)/lib
	cp $(ETCFILES) $(INSTDIR)/etc
	cp -ar etc/openvpn $(INSTDIR)/etc
	sed -i -e 's@^rundir=.*@rundir=/var/media/ftp/ffritz@' $(INSTDIR)/etc/ff_atom_startup
	make -C ../lirc install DESTDIR=$(INSTDIR)
	make -C ../libupnpp install DESTDIR=$(INSTDIR)
	make -C ../upmpdcli install DESTDIR=$(INSTDIR)
	make -C ../nfs install DESTDIR=$(INSTDIR)
	cp -a bin/ffwrap $(INSTDIR)/bin/exec
	@cd $(INSTDIR)/bin; \
	    for f in `ls | xargs file | grep ELF | sed -e 's/:.*//'`; do\
		strip $$f;\
		mv $$f exec/$$f;\
		ln -sv exec/ffwrap $$f;\
	    done
	@cd $(INSTDIR)/lib; \
	    for l in `ls | xargs file | grep ELF | sed -e 's/:.*//'`; do\
		strip $$l;\
	    done
	
clean: 
	rm -rf output $(IMAGE) ffimage.bin

cleanall:
	for d in $(SUBDIRS); do make -C $${d} clean; done
