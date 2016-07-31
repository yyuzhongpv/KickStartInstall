#!/bin/bash

ldapsearch -x -w PvamuCloud -D "cn=admin,dc=master,dc=com" -H ldap://127.0.0.1 -b "uid=$1,ou=People,dc=master,dc=com"

