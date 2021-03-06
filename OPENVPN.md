OpenVPN Integration (experimental)
==================================

An OpenVPN server will be started on the Atom core if persistent configuration data
has been generated (see below).

This particluar sample configuration starts OpenVPN as server in bridge mode
with TLS. A connecting client is integrated into the LAN side of the box 
(192.168.178 network by default).

For this to work the following steps are performed at startup:

- Startup script (etc/run_openvpn)
	- Executed at box startup. Terminates if no openvpn.conf present.
	- Will assign an additional address to the Atom core so that it
	  is possible to define a port forwarding rule in the FritzOS GUI
	  (it is not possible to define a rule for the standard IP 192.168.178.254).
	  The additional IP is one below the regular IP, e.g. 192.168.178.253.
	- Starts the openvpn daemon listening at the default UDP port 1194

- OpenVPN configuration (openvpn.conf)
	- Configures the server in "server-bridge" mode.
	- Default IP range assigned to clients is 192.168.178.200 .. 220. Change this
	  if required.
	- Executes the "tap-up" script in etc/openvpn when the tap interface is created.
	  This script will bring up the tap interface and integrate it into the "lan"
	  bridge to provide access to the LAN domain.
	- Enables TLS (see below)

Installation steps required by the user (once)
----------------------------------------------
- Create the directory /var/tmp/ffnvram/root-ssh/openvpn (permission 700).
  All files mentioned below must be copied into this directory.
- Create the daemon configuration file openvpn.conf.
  /usr/local/etc/openvpn/openvpn.conf.template can be used as template.
- Create/install TLS keys and certificates (see easy-rsa example below):
	- ca.crt 	- The CA authority file
	- dh.pem 	- Diffie Hellman parameters
	- machine.cert	- The certificate for the FritzBox
	- machine.key	- The box private key
- Make checges persistent by calling "nvsync"
- Define an UDP forwarding rule in the FritzOS GUI for UDP port 1194 to some host 
  in the local network (this host should not use this port).
  This rule will be re-defined by the startup script so that it reaches port 1194
  on the FritzBox.
- Create keys/certificates for the clients as required.


TLS using easy-rsa
==================

Set up:

	git clone https://github.com/OpenVPN/easy-rsa.git
	cd easy-rsa/easyrsa3
	./easyrsa init-pki
	./easyrsa build-ca

For the Fritzbox (server):

	./easyrsa build-server-full fbox nopass
	scp ./pki/ca.crt ./pki/dh.pem root@192.168.178.1:/var/tmp/ffnvram/root-ssh/openvpn
	scp ./pki/private/fbox.key root@192.168.178.1:/var/tmp/ffnvram/root-ssh/openvpn/machine.key
	scp ./pki/issued/fbox.crt root@192.168.178.1:/var/tmp/ffnvram/root-ssh/openvpn/machine.cert
	ssh root@192.168.178.1 nvsync

For the clients:

	./easyrsa build-client-full myclient

Use pki/ca.crt, private/myclient.key and issued/myclient.crt for client initialization.

TODO
====
- Use Box DHCP server to assign addresses


PERFORMANCE
===========

My performance numbers:

	Cipher		Speed (Mbit/s)	openvpn daemon load
	---------------	---------------	-------------------
	BF-CBC		32 		47%
	none		54		45%
	AES-128-CBC	29		47%
	

The setup is:

	PC[192.168.20.1] --- LAN --> Atom[192.168.20.253] -> OpenVPN -> lan bridge -> Cable(80mbit/sec) -> speedtest

