# KickStartInstall
Install CentOS 7 on Cluster with KickStart

1. Download CentOS 7 iso file.

wget http://buildlogs.centos.org/rolling/7/isos/x86_64/CentOS-7-x86_64-DVD.iso

2. Setup env on master node.

    yum -y install createrepo mkisofs

3. Config network on master node.

    /etc/sysconfig/network-scripts/ifcfg-eno1:

	TYPE=Ethernet
	BOOTPROTO=none
	DEFROUTE=yes
	IPV4_FAILURE_FATAL=no
	IPV6INIT=yes
	IPV6_AUTOCONF=yes
	IPV6_DEFROUTE=yes
	IPV6_FAILURE_FATAL=no
	NAME=eno1
	UUID=a767bb25-dedc-4e86-8f2c-38de0105a303
	DEVICE=eno1
	ONBOOT=yes
	IPADDR=172.30.50.2
	PREFIX=24
	DNS1=8.8.8.8
	IPV6_PEERDNS=yes
	IPV6_PEERROUTES=yes
	IPV6_PRIVACY=no

    /etc/sysconfig/network-scripts/ifcfg-eno2:

	TYPE=Ethernet
	BOOTPROTO=none
	DEFROUTE=yes
	IPV4_FAILURE_FATAL=no
	IPV6INIT=yes
	IPV6_AUTOCONF=yes
	IPV6_DEFROUTE=yes
	IPV6_FAILURE_FATAL=no
	NAME=eno2
	UUID=86cb6f9e-4170-4c8e-9b8a-ea02ac4addb1
	DEVICE=eno2
	ONBOOT=yes
	IPADDR=129.207.46.224
	PREFIX=24
	GATEWAY=129.207.46.1
	DNS1=8.8.8.8
	IPV6_PEERDNS=yes
	IPV6_PEERROUTES=yes
	IPV6_PRIVACY=no

4. Setup iptables

	systemctl mask firewalld
	systemctl stop firewalld
	yum install iptables-services
	systemctl enable iptables
	systemctl start iptables


	echo 1 > /proc/sys/net/ipv4/ip_forward

	iptables -F
	iptables -t nat -F
	iptables -t mangle -F

	iptables -t nat -A POSTROUTING -o eno2 -j MASQUERADE
	iptables -A FORWARD -i eno1 -j ACCEPT

	You will need to edit /etc/sysctl.conf and change the line that says net.ipv4.ip_forward = 0 to net.ipv4.ip_forward = 1.

	You will need to edit /etc/sysconfig/iptables-config and make sure IPTABLES_MODULES_UNLOAD, IPTABLES_SAVE_ON_STOP, and IPTABLES_SAVE_ON_RESTART are all set to 'yes'.

5. DHCP config

	yum install -y dhcp

	/etc/dhcp/dhcp.conf:

	default-lease-time 600;
	max-lease-time 7200;
	log-facility local7;

	subnet 172.30.50.0 netmask 255.255.255.0 {
	  range 172.30.50.4 172.30.50.254;
	  option routers 172.30.50.2;
	  next-server 172.30.50.2;
	  filename "pxelinux.0";
	}

	systemctl start dhcpd
	systemctl enable dhcpd
	systemctl restart dhcpd

6. tftp config

	yum install -y tftp*
	yum install -y xinetd
	systemctl start xinetd
	systemctl enable xinetd

	/etc/xinet.d/tftp

	service tftp
	{
		socket_type		= dgram
		protocol		= udp
		wait			= yes
		user			= root
		server			= /usr/sbin/in.tftpd
		server_args		= -s /var/lib/tftpboot
		disable			= no
		port			= 69
		per_source		= 11
		cps			= 100 2
		flags			= IPv4
	}

	systemctl start tftp

7. yum install -y syslinux
	sestatus
	cat /etc/sysconfig/selinux, change and reboot
	SELINUX=enforcing
	sestatus

8. Prepare /var/lib/tftpboot/.

	cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/

	mount -t iso9660 -o loop /root/CentOS-7-x86_64-DVD.iso /mnt/centos/

	cp /mnt/centos/images/pxeboot/{vmlinuz,initrd.img} /var/lib/tftpboot/

	cp /mnt/centos/isolinux/{boot.msg,vesamenu.c32,splash.png} /var/lib/tftpboot/

9. Prepare /var/www/html/centos7

	mkdir /var/www/html/centos7

	mount -t iso9660 -o loop /root/CentOS-7-x86_64-DVD.iso /var/www/html/centos7/

	cp /root/anaconda-ks.cfg /var/www/html/ks.cfg

	change ks.cfg
	Look in /etc/httpd/conf/httpd.conf for ServerName. Change that:
		ServerName 129.207.46.224:80 

	restart http

10. /var/lib/tftpboot/pxelinux.cfg/default

	label linux
	  menu label ^Install CentOS 7
	  kernel vmlinuz
	  append initrd=initrd.img ip=dhcp inst.ks=http://172.30.50.2/ks.cfg inst.repo=http://172.30.50.2/centos7 quiet

11. /var/www/html/ks.cfg

	url --url http://172.30.50.2/centos7
	repo --name=optional --baseurl=http://172.30.50.2/centos7

	text

	firstboot --enable
	ignoredisk --only-use=sdb

	keyboard --vckeymap=us --xlayouts='us'

	lang en_US.UTF-8

	network  --bootproto=dhcp --device=enp0s26u1u5u5 --onboot=on --activate
	network  --bootproto=dhcp --device=eno1 --onboot=on --activate
	network  --bootproto=dhcp --device=enp6s0f1 --onboot=on --activate
	network  --bootproto=dhcp --device=eno3 --onboot=off --ipv6=auto
	network  --bootproto=dhcp --device=eno4 --onboot=off --ipv6=auto
	network  --hostname=compute000

	rootpw "123456"

	timezone America/chicago --isUtc

	bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sdb

	clearpart --all --initlabel --drives=sdb

	part /var --fstype="ext4" --ondisk=sdb --size=28610
	part / --fstype="ext4" --ondisk=sdb --size=195367
	part swap --fstype="swap" --ondisk=sdb --size=38146
	part /boot/efi --fstype="efi" --ondisk=sdb --size=9536 --fsoptions="umask=0077,shortname=winnt"
	part /home --fstype="ext4" --ondisk=sdb --size=4908
	part /boot --fstype="ext4" --ondisk=sdb --size=8570


12. Troubleshooting of tftp.

	is tftpd run from xinetd or as an independent daemon?
	do you need to alter /etc/hosts.allow or hosts.deny
	is SELinux enabled (check with "getenforce" command)?
	is there a host firewall running? (service iptables status)
	are you sure of the directory tftpd is useing as it's data dir?
	does the file you are attempting to "get" actually exist?

13. Boot from PXE0, and install system.
    Change boot order, make HD0 to be the first one and reboot

14. Configure all compute nodes
    In Master node: dhcpd.conf   binding MAC with IP address
    change hostname /etc/sysconfig/network /etc/hosts
    mount home from NFS  /etc/fstab
    reboot

15	NFS
 	yum -y install nfs-utils

 	vi /etc/exports
	/home 10.0.0.0/24(rw,no_root_squash)
	systemctl start rpcbind nfs-server 
	systemctl enable rpcbind nfs-server 

