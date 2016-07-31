#!/bin/bash

groupname=$1
groupid=$2

ext=".ldif"
groupfile="group_$groupname$ext"

echo "dn: cn=$groupname,ou=Group,dc=master,dc=com" > $groupfile
echo "objectClass: posixGroup" >> $groupfile
echo "objectClass: top" >> $groupfile
echo "gidNumber: $groupid" >> $groupfile

ldapadd -x -w PvamuCloud -D "cn=admin,dc=master,dc=com" -f $groupfile
