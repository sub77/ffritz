Introduction 
============
This is a repository containing my modifications for FritzBox-6490 Cable.
You still need the original image to build a modified install image, and you
need a way to upgrade.  I'm assuming you already have telnet/ssh access to
the box by either already running a modified image or having gained access.

It _might_ work on the FritzBox 6590, but i have never tested it.

There are some known methods how to perform an initial firmware update
from a box that runs an original image.
The one known to work on current firmware versions is to directly write 
kernel and filesystem images via the boot loader (eva). Search IPPF threads
for information on how to accomplish this.

I take no responsibility for broken devices or other problems (e.g. with
your provider).  Use this at your own risk.

If you don't trust my binaries, everything (hopefully) that is required to
rebuild them is located below packages.

Have Fun,
<f/e/s/c/2/0/0/0/@/g/m/a/i/l/./c/o/m>

Usage
=====

Creating an install/update image
--------------------------------

- Obtain original install image (default is
    FRITZ.Box_6490_Cable.de-en-es-it-fr-pl.141.06.85.image)

- Clone repository (master branch) in the directory where the original
    install image is located:

    `git clone https://fesc2000@bitbucket.org/fesc2000/ffritz.git`

- Go to ffritz directory and `make clean; make` (sudo required).

IMPORTANT NOTE
--------------

Before starting to modify the FritzBox, it is always recommended
to generate extended support data (<http://192.168.178.1/support.lua>)
and save it. It might become (very) useful to "unbrick" your Box ...

Installing the image from the Boot Loader (if box has no telnet/ssh login)
--------------------------------------------------------------------------

Please consult the web/IPPF threads. I have personally never done it this
way so i won't document it here.

Installing the image (with ssh/telnet access)
---------------------------------------------

- Copy the release tar image to the box, e.g. NAS (/var/media/ftp)
- Log in to primary IP address (default 192.168.178.1), which is the ARM
  core on older firmware and Atom on Firmware 6.8 onwards.
- Extract in the root directory:

~~~
	cd /
	tar xf /var/media/ftp/fb6490_XXX.tar
~~~

- Call "var/install" (from the root directory!)
	- Monitor the output on the console (1st telnet/ssh login session).
	  There should be a SUCCESS message at the end.
	- The return code $? of var/install should be 1
- After successful installation, execute "/sbin/reboot".

Installation issues
-------------------

If the return code is not 1, check the console messages. Known errors are

- ARM Calling additional procedure failed: UPDATE FAIL (1)
    It is likely that there was a problem with the certificate update,
    probably because the box does not have current certificates and new
    certificates could not be obtained (missing network connection?).

    The image has been installed, but the boot bank has not been switched
    (i.e.  the box will still boot the current image).
    To switch to the new image anyway, execute var/switch_image and apply
    the instructed command.

- Installer not called from root directory (then the "dd" command can't
    be found)

First use
---------

After first installation there is no login password for ssh. To assign one:

- Log in to the box using telnet and the web password within the first 10
  minutes after startup.
- Call "passwd" to change the root password
- Call "nvsync" to make the change persistent
- Consider doing this again using ssh, and change the web gui password
  afterwards if you are paranoid regarding telnet.

Firmware 6.8 onwards:
To be able to log in to the arm core (address 169.254.1.2 from atom) you might
want to copy the shadow file to persistent storage on arm core:

	rpc sh -c "rpc_cp /etc/shadow /nvram/shadow"

Features
========

Persistent storage
------------------
Various data is stored persistently in an encrypted tar archive
(/var/media/ftp/ffritz/data/ffstore.dat). The password to this
storage is also stored here persistenty (key.enc), but it is
encrypted.

ffstore.dat is basically a tar image of everything below /var/tmp/ffnvram.
By default this is

- the password database (shadow file)
- dropbear data (dropbear directory)
- the roots .ssh directory (root_ssh directory), which also contains a subfolder
  with the data for OpenVPN (root_ssh/openvpn).

If no ffstore.dat or key.enc is present, or can't be loaded for some reason,
an attempt is made to get the data from the /nvram partition of the SPI
flash (as it was done in previous versions).

The nvsync tool re-generates the persistent storage with the contents of 
/var/tmp/ffnvram.

telnet (Atom)
-------------
- A telnetd service is started at boot time and killed after 600 seconds.

dropber/ssh/scp (Atom)
----------------------
- The dropbear host key (/var/tmp/dropbear/dropbear_rsa_host_key) is always
  overwritten with the data derived from the web/SSL key of the box
  (/var/flash/websrv_ssl_key.pem).
- In order to use a different box key, create the file
  /var/tmp/dropbear/rsa_key_dontoverwrite and create a different rsa key
  using dropbearkey.
  Don't forget to save the chages using nvsync.

dropbear/ssh/scp (Arm)
----------------------
- There is a dropbear service running on arm core which fetches it's persistent
  data from /nvram. This might be dropped in future.
- If no password is assigned, use the rpc command to transfer the shadow file
  from atom to arm

    rpc sh -c "rpc_cp /etc/shadow /nvram/shadow"

openssl (Atom)
---------------------------
- /usr/bin/openssl is a wrapper to make sure openssl uses the correct libraries.

IPv6 (Arm)
----------
For firmware < 6.63 selection of native IPv6 is forced to be enabled in
the GUI together with the general IPv6 availability.

pswtool: Switch tools (Arm)
---------------------------
A tool i have written to access the internal switch (in the Puma6 SoC). 

Supported features:

- Configuring VLANs (pswtool)
- Reading port counters (pswtool)

In general, -h shows detailed help.

A topology diagram that shows the usage of these two switches
is outlined in [MISC.md](MISC.html).

NOTES:

- pswtool is based on some API calls provided by libticc. It is therefore 
  limited to the few calls i could more or less re-engineer.

Software Packages
=================

In addition to the core features it is possible to install an application image
to the Atom core (see README-APP.md).

The image is distributed as ffritz-app-VERSION.tar. To install it,

- Copy it to the box NAS directory 

	scp ffritz-app-VERSION.tar root@192.168.178.1:/var/media/ftp

- Log in and install it

	ffinstall ffritz-app-VERSION.tar CHECKSUM

  The checksum is the sha256sum listed on the download page. It is also contained
  in the file ffimage.sha256sum within the release .tar archive.

- After the success message, restart the box (or read the next chapter)

Steps performed by the startup script:

- check if /var/media/ftp/ffritz/data/ffimage.bin exists
- compare its SHA256 checksum against the checksum that was given at installation.
- if it matches, ffimage.bin is mounted to /usr/local
- The target checksum is saved in the encrypted persistent storage.
- Execute /usr/local/etc/ff_atom_startup

Restart services without box reboot
-----------------------------------
If you don't want to restart the box after installing a new image:
- Stop all ffritz services:

	cp /usr/local/etc/ffshutdown /tmp; /tmp/ffshutdown

- If prompted, kill processes still using /usr/local, and re-run ffshutdown
- Run mount script for new image: /etc/init.d/S93-ffimage
- Start services: /etc/init.d/S94-ffstart

Optional Arm package
--------------------

The file ffritz-arm-VERSION.tar.gz contains some optional tools for the arm core.
It can be integrated into the install image by editing Makefile and defining its
location via the FFRITZ_ARM_PACKAGE variable.

Notes
=====

Toolchain
---------
Cross-compile toolchain for ARM is buildroot-2013.02 from the original avm
source tarball.
It is installed in packages/arm/avm (just do a make there).

For Atom, the toolchain is buildroot-2013.02 (packages/x86/buildroot).
The atom source tarball (packages/x86/avm) does not work for me.

Build Host
----------

Tested: Debian 7, Debian 8, CentOS 7.

Used disk space is ca. 10G.

Required (debian) packages are:
squashfs-tools busybox rsync sudo gcc g++ flex bison git libncurses-dev gettext unzip automake

Big endian squashfs tools
-------------------------

Binaries are provided in the "hosts" directory. If they dont work, try cloning
freetz and build them using "make squashfstools-be".

There is a make rule squashfstools-be that does this.

Required (debian) packages are:
apt-get install gawk libtool realpath pkg-config zlibc gnulib libcap-dev

You might have to remove "composite" and "sys/acl.h" from the
.build-prerequisites file
