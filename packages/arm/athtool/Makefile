
# Use AVM toolchain by default
#
ifeq ($(BUILDROOT),)
BUILDROOT   = $(shell cd ../avm/build/prefix_sehr_sehr_sehr_sehr_sehr_sehr_sehr_sehr_sehr_lang_buildroot-2013.05/; pwd)
endif

ifeq ($(BUILDROOT),)
$(error BUILDROOT (buildroot top directory) not defined)
endif

ifeq ($(CROSS_COMPILE),)
CROSS_COMPILE=armeb-buildroot-linux-uclibcgnueabi-
endif


###############################################################################

TOPDIR=$(shell pwd)
TOOLCHAIN   = $(shell cd $(BUILDROOT)/output/host/usr/bin/; pwd)
DESTDIR	    = $(TOPDIR)/output
TGTLIB	    = ../../../arm/squashfs-root/lib

export PATH := $(TOOLCHAIN):$(PATH)

###############################################################################

TARGETS	    = athtool mdio-release pswtool

all:	$(TGTLIB) $(TARGETS)


athtool:	athtool.o athtool_vlan.o athtool_counters.o athtool_atu.o
athtool:	LDFLAGS=-L$(TGTLIB) -lticc
mdio-release:	mdio-release.o
pswtool:	pswtool.o pswtool_counters.o
pswtool:	LDFLAGS=-L$(TGTLIB) -lticc

$(TGTLIB):
	make -C ../../.. arm/squashfs-root

install:    all
	cp $(TARGETS) $(INSTDIR)/bin

clean:
	rm -f $(TARGETS) *.o *.d

doc:	html/index.html

html/index.html:    $(wildcard *.c *.h) Doxyfile
	doxygen Doxyfile

include ../../rules.mk
-include $(wildcard *.d)
