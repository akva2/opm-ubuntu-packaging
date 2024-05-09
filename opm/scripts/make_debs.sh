#!/bin/bash

ROOT=$1
DIST=$2
export DEB_BUILD_OPTIONS="parallel=$3"
export DEBEMAIL="$4"
OPM_VER=$5

set -e

pushd $ROOT/output

MODULE_LIST="opm-common opm-grid opm-models opm-simulators opm-upscaling"
for module in ${MODULE_LIST}
do
  su builder -c "gbp clone https://salsa.debian.org/science-team/$module"
  ls
  cd $module
  debian_version=`head -n1 debian/changelog | sed -e 's/.*(\(.*\)).*/\1/g' | cut -d '-' -f -1`
  su builder -c "gbp export-orig"
  opm_version=`echo $debian_version | awk -F '+' '{print $1}'`
  mv ../${module}_${debian_version}.orig.tar.xz ../${module}_${opm_version}.orig.tar.xz
  TITLE="New release for Ubuntu $DIST"
  su builder -c "dch -b -v $opm_version-${OPM_VER}~$DIST -D $DIST --force-distribution --empty $TITLE"
  if test "$DIST" == "jammy"
  then
    echo -e "\noverride_dh_dwz:\n\tdh_dwz -- -L 100000000" >> debian/rules
  fi
  cd ..
  DEBIAN_FRONTEND=noninteractive mk-build-deps --install --remove --tool='apt-get -o Debug::pkgProblemResolver=yes --yes' $module/debian/control 
  cd $module 
  chown builder:builder * -R
  rm .git -Rf
  su builder -c "debuild -S -uc -us"
  su builder -c "debuild -b -uc -us"
  cd ..
  rm $module -R
  dpkg -i *deb 
done

popd
