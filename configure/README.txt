1. Server

yum install -y openldap openldap-servers openldap-clients

vim /etc/openldap/slapd.conf  
	//copy from https://wiki.gentoo.org/wiki/Centralized_authentication_using_OpenLDAP/zh
	//change several lines!!!

vim /etc/rsyslog.conf   
	local4.* /var/log/ldap.log

chown -R ldap:ldap /etc/openldap/slapd.d/
chown -R ldap:ldap /etc/openldap/openldap-data

systemctl restart rsyslog.service
systemctl start slapd.service

rm -rf /etc/openldap/slapd.d/*

slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d

systemctl restart slapd.service

useradd ldapuser1
passwd ldapuser1

yum install migrationtools -y
cd /usr/share/migrationtools/

vim migrate_common.ph 
	DEFAULT_MAIL_DOMAIN master.com
	DEFAULT_BASE dc=master,dc=com

./migrate_base.pl > /tmp/base.ldif
./migrate_passwd.pl /etc/passwd > /tmp/passwd.ldif
./migrate_group.pl /etc/group > /tmp/group.ldif

ldapadd -x -D "cn=admin,dc=master,dc=com" -W -f /tmp/base.ldif
ldapadd -x -D "cn=admin,dc=master,dc=com" -W -f /tmp/passwd.ldif
ldapadd -x -D "cn=admin,dc=master,dc=com" -W -f /tmp/group.ldif

systemctl restart  slapd.service


cp /usr/share/doc/sudo-1.8.6p7/schema.OpenLDAP /etc/openldap/schema/sudo.schema

/etc/openldap/slapd.conf
	include         /etc/openldap/schema/sudo.schema

rm -rf /etc/openldap/slapd.d/*
sudo -u ldap slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d
service slapd restart


Create sudo.ldif
	dn: dc=master dc=com
	objectClass: top
	objectClass: organizationalUnit
	ou: Sudoers

	dn: cn=defaults,dc=master,dc=com
	objectClass: top
	objectClass: sudoRole
	cn: defaults
	sudoOption: !visiblepw
	sudoOption: always_set_home
	sudoOption: env_reset
	sudoOption: requiretty

	dn: cn=test,dc=master,dc=com
	objectClass: top
	objectClass: sudoRole
	cn: test
	sudoCommand: ALL
	sudoHost: ALL
	sudoOption: !authenticate
	sudoRunAsUser: ALL
	sudoUser: test 

ldapadd -x -D "cn=admin,dc=master,dc=com" -W -f sudo.ldif

/etc/sudo-ldap.conf

	uri ldap://172.30.50.2
	sudoers_base dc=master,dc=com

2. Slave nodes

vim /etc/resolv.conf
	nameserver  8.8.8.8

yum -y install openldap openldap-clients nss-pam-ldapd pam_ldap

echo "session required pam_mkhomedir.so skel=/etc/skel umask=0077" >> /etc/pam.d/system-auth

vi /etc/pam.d/password-auth-ac
	#auth requisite pam_succeed_if.so uid >= 1000 quiet_success

authconfig --savebackup=auth.bak

authconfig --enableldap --enableldapauth --enablemkhomedir --enableforcelegacy --disablesssd --disablesssdauth --ldapserver=172.30.50.2 --ldapbasedn="dc=master,dc=com" --update

ssh ldapuser1@172.30.50.4 on 172.30.50.2 OK!!!

getent passwd |grep ldapuser1  //Debug
ldapsearch -x -H ldap://172.30.50.2 -b 'dc=master,dc=com'

Change on Storage01 node to sharing all user info with openldap.
$ vim /etc/openldap/ldap.conf
add 
BASE:dc=master,dc=com
URL:172.30.50.2   
 
$ vim /etc/nslcd.conf
uri ldap://172.30.50.2
base dc=master,dc=com
 
$ vim /etc/nsswitch.conf
passwd:     files ldap
shadow:     files ldap
group:      files ldap
 
$ vim /etc/sysconfig/authconfig
USESYSNETAUTH=yes  
USESHADOW=yes
USELOCAUTHORIZE=yes
USELDAP=yes
USELDAPAUTH=yes
USEMD5=yes        
USEMKHOMEDIR=yes
PASSWDALGORITHM=sha512   

$ cp /etc/pam.d/system-auth /etc/pam.d/system-auth.bak
$ vim /etc/pam.d/system-auth
auth        sufficient    pam_ldap.so

account     [default=bad success=ok user_unknown=ignore] pam_ldap.so
 
password    sufficient    pam_ldap.so use_authtok
 
session     optional      pam_ldap.so
session     optional      pam_mkhomedir.so skel=/etc/skel/ umask=0022

$ service nslcd start && chkconfig --level 2345 nslcd on

3. New User, create in linux as normal, then

create new yzyan.ldif
	dn: uid=yzyan,ou=People,dc=master,dc=com
	uid: yzyan
	cn: yzyan
	objectClass: account
	objectClass: posixAccount
	objectClass: top
	objectClass: shadowAccount
	userPassword: {crypt}x
	shadowLastChange: 0
	shadowMin: 0
	shadowMax: 99999
	shadowWarning: 7
	loginShell: /bin/bash
	uidNumber: 1002
	gidNumber: 1002
	homeDirectory: /home/yzyan

and create new group yzgroup.ldif

	dn: cn=yzyan,ou=Group,dc=master,dc=com
	objectClass: posixGroup
	objectClass: top
	gidNumber: 1002

ldapadd -x -W -D "cn=admin,dc=master,dc=com" -f yzgroup.ldif

ldapadd -x -W -D "cn=admin,dc=master,dc=com" -f  yzyan.ldif
ldappasswd -s yzyan -W -D "cn=admin,dc=master,dc=com" -x "uid=yzyan,ou=People,dc=master,dc=com"

ldapdelete -W -D "cn=admin,dc=master,dc=com" "uid=yzyan,ou=People,dc=master,dc=com"


4. Solve the problem of mounted dir with nobody:nobody.

   vim /etc/idmapd.conf on both client and server sides. 

   Domain = pvamucscloud.edu

   # server information (REQUIRED)
    LDAP_server = 172.30.50.2

    # the default search base (REQUIRED)
    LDAP_base = cn=admin,dc=master,dc=com
 
    Server:
    service nfs restart
    service rpcidmapd restart

    vim /etc/exports
    /apps *(rw,no_root_squash)
    /data *(rw,no_root_squash)
    /home1 *(rw,no_root_squash)
    /scratch *(rw,no_root_squash)

    vim /etc/hosts
    172.30.50.92 storage01.pvamucscloud.edu storage01

    Client:

    vim /etc/fstab
    172.30.50.92:/home1 /home1   nfs rw    0       0
    172.30.50.92:/data  /data   nfs rw    0       0
    172.30.50.92:/apps  /apps  nfs rw    0       0
    172.30.50.92:/scratch   /scratch   nfs rw    0       0

    vim /etc/hosts
    172.30.50.92 storage01.pvamucscloud.edu storage01

    service rpcidmapd restart
    umount
    mount -a

    root cause: http://www.softpanorama.org/Net/Application_layer/NFS/Troubleshooting/nfsv4_mounts_files_as_nobody.shtml

5. reference
	http://www.zhukun.net/archives/7548
	https://wiki.gentoo.org/wiki/Centralized_authentication_using_OpenLDAP/zh
	http://www.centoscn.com/CentosServer/test/2015/0320/4927.html
	https://www.52os.net/articles/openldap-install-and-settings.html
	http://www.thegeekstuff.com/2015/02/openldap-add-users-groups/
