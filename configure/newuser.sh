#!/bin/bash

username=$1
password=$2
userid=$3
groupid=$4

ext=".ldif"
userfile="user_$username$ext"
groupfile="group_$username$ext"

echo "dn: uid=$username,ou=People,dc=master,dc=com" > $userfile
echo "uid: $username" >> $userfile
echo "cn: $username" >> $userfile
echo "objectClass: account" >> $userfile
echo "objectClass: posixAccount" >> $userfile
echo "objectClass: top" >> $userfile
echo "objectClass: shadowAccount" >> $userfile
echo "userPassword: {crypt}x" >> $userfile
echo "shadowLastChange: 0" >> $userfile
echo "shadowMin: 0" >> $userfile
echo "shadowMax: 99999" >> $userfile
echo "shadowWarning: 7" >> $userfile
echo "loginShell: /bin/bash" >> $userfile
echo "uidNumber: $userid" >> $userfile
echo "gidNumber: $groupid" >> $userfile
echo "homeDirectory: /home/$username" >> $userfile

echo "dn: cn=$username,ou=Group,dc=master,dc=com" > $groupfile
echo "objectClass: posixGroup" >> $groupfile
echo "objectClass: top" >> $groupfile
echo "gidNumber: $groupid" >> $groupfile

ldapadd -x -w PvamuCloud -D "cn=admin,dc=master,dc=com" -f $groupfile
ldapadd -x -w PvamuCloud -D "cn=admin,dc=master,dc=com" -f $userfile
ldappasswd -s $password -w PvamuCloud -D "cn=admin,dc=master,dc=com" -x "uid=$username,ou=People,dc=master,dc=com"
