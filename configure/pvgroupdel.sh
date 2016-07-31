#!/bin/bash

ldapdelete -w PvamuCloud -D "cn=admin,dc=master,dc=com" "cn=$1,ou=Group,dc=master,dc=com"

