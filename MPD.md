I thouhgt it would be nice to have mpd (music player daemon) and shairport
(AirPlay receiver) running on the Atom core of the FritzBox, with some
USB DAC/Codec as output.

usbplayd
========

This daemon is started to provide audio output. It polls a set of named pipes
and plays data from one of them to the selected usb audio device. If required it
will convert the sample rate.

usbplayd is configured in /var/media/ftp/ffritz/usbplayd.conf.
The default content is:

    USBPLAYD_ARGS=-P /var/tmp/mpd.fifo:44100 -P /var/tmp/shairport.fifo:44100

Which means that two pipes are generated, one for mpd and one for shairport
The default sample rate is 44100 (i.e. mpd and shairport need to provide this
sample rate).

If you have a usb audio device which only supports 48000Hz (like i do)
usbplayd will resample the "fifo rate" to the "device rate" using
libsamplerate.

If you have a device that supports configurable rates you might
want to add the parameter "-r 44100" to configure the usb device to this
rate. This will avoid resampling if the default rate differs, but not all
devices seem to support this.

To get a list of usb devices and the attributes, call "usbplayd -l".

The output volume of the device is adjusted in /var/tmp/volume. This file 
is polled by usbplayd and the volume is adjusted according to the ASCII integer
(0..100) in the file.
The modified mpd/shairport binaries in this package supports this feature.

Note that the shairport fifo has precedence over the mpd fifo, i.e. if 
shairport starts playing, mpd is effectively muted until shairport stops.
This behaviour is determined by the order of the -P parameters to usbplayd.

Sample rate conversion
----------------------

usbplayd will use libsamplerate if pipe and device sample rate mismatches.
The maximum supported ratio is 4 (device rate / pipe rate).

libsamplerate has different algorithms:
- SRC_SINC_BEST_QUALITY
- SRC_SINC_MEDIUM_QUALITY
- SRC_SINC_FASTEST
- SRC_ZERO_ORDER_HOLD
- SRC_LINEAR

The "best quality" algorithm results in a CPU load of ca 50% (44.1KHz -> 48KHz).
The default is SRC_SINC_FASTEST (ca. 7% load).
Add the -c switch to USBPLAYD_ARGS to change the default.

MPD
===

mpd is started via etc/runmpd. By default it will use the fifo output plugin
to write data to /var/tmp/mpd.fifo at a sample rate of 44100Hz.

The configuratin file is var/media/ftp/ffritz/mpd.conf.
mpd runtime files (database, log, etc) are stored in var/media/ftp/ffritz/.mpd.

The default Music database is /var/media/ftp/Musik.

mpd can be manually started with the etc/runmpd script. This script will also
start usbplayd if required.

If you do not want to start mpd, create /var/media/ftp/.skip_mpd

Volume Control
--------------
The mpd binary in this package has been modified to support hardware volume control
in combination with the pipe/fifo output plugins by means of a "volume" file 
(see usbplayd).

This is done by setting the mixer type of pipe/fifo in mpd.conf to "hardware"
and specifying the "volume_file" attribute.

The default mpd.conf uses /var/tmp/volume as expected by usbplayd.

NFS Mounts
----------
If you want to mount an external database, use the .mtab feature as described in README.
For example is use this entry in /var/media/ftp/ffritz/.mtab so that mpd can access
my music database on an external NAS:

    MOUNT Musik/NAS nas:Multimedia/Music

Shairport
=========
shairport will announce itself as "fFritz". It will output data to /var/tmp/shairport.fifo.

shairport can be manually started with the etc/run_shairport script. This script will also
start usbplayd if required.

The pipe output driver accepts a second parameter, which is the file where the volume 
level is written to (/var/tmp/volume in this case).

Tested with Android AirAudio app.

If you do not want to start shairport, create /var/media/ftp/.skip_shairport

Integration details
===================
- mpd/shairport run as user ffritz, group usb for security reasons.

TODO
====