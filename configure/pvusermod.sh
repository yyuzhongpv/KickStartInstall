#!/bin/bash

newgroup=$1
username=$2

ext=".ldif"
groupfile="chgrp_$username$newgroup$ext"

echo "dn: cn=$newgroup,ou=Group,dc=master,dc=com" > $groupfile
echo "changetype: modify" >> $groupfile
echo "add: memberuid" >> $groupfile
echo "memberuid: $username" >> $groupfile

ldapmodify -x -w PvamuCloud -D "cn=admin,dc=master,dc=com" -f $groupfile
