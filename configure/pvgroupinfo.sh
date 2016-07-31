#!/bin/bash

ldapsearch -x -w PvamuCloud -D "cn=admin,dc=master,dc=com" -H ldap://127.0.0.1 -b "cn=$1,ou=Group,dc=master,dc=com"

