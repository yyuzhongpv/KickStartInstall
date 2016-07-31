#!/bin/bash

ldapdelete -w PvamuCloud -D "cn=admin,dc=master,dc=com" "uid=$1,ou=People,dc=master,dc=com"

