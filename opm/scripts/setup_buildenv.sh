#!/bin/bash

DEBIAN_FRONTEND=noninteractive apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y install wget dpkg-dev devscripts equivs git-buildpackage software-properties-common
apt-add-repository ppa:opm/$1
DEBIAN_FRONTEND=noninteractive apt-get -y update

exit 0
