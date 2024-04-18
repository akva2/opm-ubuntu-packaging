#!/bin/bash

apt-get update
apt-get -y upgrade
apt-get -y install wget dpkg-dev devscripts equivs

exit 0
