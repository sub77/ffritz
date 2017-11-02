Change history of application package
=====================================

Release 4
---------
- Fix tmpfs memory leak: fflogrotate got lost along the way,
  /var/log/ffritz.log could become big over time.
- Fix upmpdcli startup issue
- Limit logrotate backup to 250K
- ffdaemon: can be stopped with SIGTERM, will reap worker
- Added etc/ffshutdown
- Added -u option to etc/usrmount

Release 3
---------
- Add 100 second startup angst delay.
  ffritz services (USB, OpenVPN) get in conflict with fb startup,
  especially on 6.85.

Release 2
---------
- Fix irexec (failed to execute commands due to wrong sh path)
- Updated libusb version to 1.0.21
- Started Bluetooth support
	- Requires updating /var/media/ftp/ffritz/usbplayd.conf
	  with

    USBPLAYD_ARGS=-P /var/tmp/mpd.fifo:44100 -P /var/tmp/shairport.fifo:44100 -P /var/tmp/bt.fifo:44100

Release 1
---------
- Renamed from release 14 of combined core/application release
- Re-packaged as squashfs binary to be installed using ffinstall

TODO
----
- Bluetooth
	- Play pipe should not be opened until playback
	  starts.
	- Provide proper pairing (e.g. only when pressing
	  WPS button..)


Change history of ffritz core integration:
==========================================

release 16
-------------------------------
- Tested Firmware 6.85
	- Update might require re-enabling the OpenVPN
  	  forwarding rule.

release 15 
-------------------------------
- Add support for Firmware 6.83
- Arm
	- Don't start temporary telnetd any more
	- Don't invoke atom startup
- Atom
	- Application tarball is no longer integrated into root
	  filesystem
		- Replaced by sqaushfs image mounted at startup
		  (/var/media/ftp/ffritz/data/ffimage.bin)
		- Only if sha256 checksum matches
	- Support for 6.83 (older versions no longer tested)
	- Replace nvram access by an encrypted storage on the nas
		(/var/media/ftp/ffritz/data/ffstore.dat)
		- Runtime copy is in /tmp/ffnvram
		- Added nvsync tool to store current state of
		  ffnvram to ffstore
		- Lacking a ffstore.dat, ffnvram is populated
		  traditionally from /nvram
	- Dropbear, openssl and telnetd are part of default
	  squashfs install image.
	- Start temporary telnetd
	- mpd
		- add libnfs support
	- usrmount/.mtab
		- uses fuse-nfs (kernel no longer supports nfs).
		- The options field in .mtab has changed and needs
		  to be adjusted:
		  It is the servers URI in libnfs format
		  (nfs://server/share), followed by additional options
		  for fuse-nfs.
	- added openssl binary
	- add build of privatekeypassword
	- Change license of source to GPLv3 to be compatible with
	  apache code

release 14
----------
- Atom
	- Add OpenVPN (experimental). See OPENVPN.md

- Arm
	- Add counter support to athtool
	- Add pswtool to access internal Puma6 L2 switch

release 13
----------
- Atom
	- buildroot
		- New gcc version (4.7.3 -> 4.9.3)
		- New binutils version (2.21.1 -> 2.23.1)
			- Host gcc 4.7 no longer required
	- New mpd version (0.19.21 -> 0.20.5)
		- mpd/upmpdcli now support LPCM/l16 audio format
- Arm
	- version 0.3 of arm package
		- added gdbserver
		- Added athtool to access box switch

release 12
----------
- Atom
	- Added upmpdcli
		- UPNP/DLNA renderer front-end for mpd
		- l16/LPCM audio is currently not supported
		  (would require latest mpd, which does not compile in this
		  toolchain)
	- Auto-start irexec
	- Moved irexec config file to /var/media/ftp/ffritz/irexec.lircrc

release 11
----------
- Atom
	- lirc
		- switch back to main lirc repository
		- replaced irdroid driver with fixed irtoy
		  NOTE: _This requires replacing/merging existing
		  lirc_options.conf with etc/lirc_options_dfl.conf!_
		- lircd sometimes crashed after the very first start.
		  Workaround is to start it in self-respawning mode
		  (via ffdaemon).
	- usbplayd
		- Fix hanging daemon
	- added ffdaemon script to start service as daemon
	- some startup/daemon output is logged to /var/tmp/ffritz.log,
	  added simple logrotate
	- moved usbplayd.pid to /var/run
	- moved mpd.pid to /var/run/mpd
	- Add udev rule for /dev/ttyACM* permission

release 10
----------
- Atom
	- Toolchain fixes for clean build
	- Added lirc
	- Added socat

release 9
---------
- Atom
	- Add libid3tag / id3 tag support to mpd
	- Fix access rights to /var/tmp/volume file at startup
	- Make usbplayd self-respawning if it crashes
	- Don't log usbplayd to /var/tmp to avoid hogging ramfs space
	- Forward dropbear stderr outputs to /dev/console
	- Create ssh symlink to dbclient
	- Added curl binary
	- Added rsync binary
- ARM
	- Make sure that ssh stuff and passwords in /nvram are not cleared
	  when a factory reset is performed (by means of entries in 
	  /etc/docsis/nvramdontremove). Only for FW 6.6x and later.
	- Do not apply ipv6 patch for 6.63 and later
	- Added Makefile option to integrate separate arm package into root
	  filesystem (ffritz-arm-XX.tar.gz, see below).
- Make sure directory permissions for /var/media/ftp/ffritz are correct

release 8
---------
- tested with firmware 6.63
- Atom
	- Added udev rule to give usb devices proper permissions (usb group)
	Remove clumsy permission fixup in runmpd
	- Put ffritz user into usb group by default
	- Fixed permission of mpd.conf
	- Added some tools:
	  strace
	  ldd
	  tcpdump
	  tcpreplay
	  su
	  mpc
	- Replaced usbplay with usbplayd, which is fifo based and accepts
	  several inputs. It also performs sample rate conversion if required.
	- Accordingly, mpd uses fifo output driver instead of pipe driver
	- Added shairport (AirPort audio receiver)
	- Added user mount table (var/media/ftp/ffritz/.mtab)
- ARM
	- Added /usr/local/etc/switch_bootbank script to help bank switch
	  without having to invoke the bootloader.
	  Also in installer tar: var/switch_bootbank
	- Use toolchain from avm source tarball for dropbear binaries

release 7
---------
- Atom
	- Add dropbear
	- Add mpd
- Arm
	- Add startup script /usr/local/etc/init.d/ff_atom_startup

release 6
---------
- Store/move dropbear keys to /nvram
- Kill telnetd after 5 minutes
- Do not start telnetd on atom by default
- Remove execution of /var/flash/debug.cfg
- Add ssh as symlink to dbclient
- Add /.ssh as symlink to /var/tmp/root-ssh, and 
  link this to nvram at startup
- Repack telnet-1.tar with busybox (same for release image)

release 5
---------
- Support for 6.62

release 4
---------
- IPV6 native tested, seems to work
- Better dropbear integration, ssh daemon started by default

release 3
---------
- Added dropbear binaries (very rudimentary)
- Start telnetd on atom core
- patch to enable native IPV6 selection

release 2 [fb6490_6.50_telnet-2.tar]
------------------------------------
- Changed etc/init.d/rc.tail.sh
		- Explicitly start telnetd from here (obviously the existence of
		  /usr/sbin/telnetd is not always sufficient)
- Added unsquashfs4_avm_x86/mksquashfs4-lzma-avm-be binaries (from Freetz)
- Fixed html tags in README
- Remove LCR download in telnet-1.tar

release 1 [fb6490_6.50_telnet.tar]
----------------------------------
- Initial release

Standalone Package History
==========================

ffritz-arm-XXX.tar.gz
---------------------
- 0.4
    - Added pswtool (for interlanl L2 switch)
    - Some fixes to athtool (counter rate calculation)
- 0.3
    - Added athtool to access box switch (see description above)
- 0.2
    - Added curl
    - Added rsync
- 0.1
    - Created, to be installed to /var/media/ftp/ffritz-arm
      Contains some libs, tcpreplay, dump, ..., strace, ldd
