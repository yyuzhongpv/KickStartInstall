#!/bin/bash

username=$1
password=$2

ldappasswd -s $password -w PvamuCloud -D "cn=admin,dc=master,dc=com" -x "uid=$username,ou=People,dc=master,dc=com"
