#!/bin/bash

ROOT=$1
DIST=$2
export DEB_BUILD_OPTIONS="parallel=$3"
export DEBEMAIL="$4"
OPM_VER=$5

set -e

pushd $ROOT/output

declare -A orig_sources
orig_sources[dune-common]="https://gitlab.dune-project.org/core/dune-common/-/archive/releases/opm/2024.04/dune-common-releases-opm-2024.04.tar.gz"
orig_sources[dune-istl]="https://gitlab.dune-project.org/core/dune-istl/-/archive/releases/opm/2024.04/dune-istl-releases-opm-2024.04.tar.gz"
orig_sources[dune-geometry]="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/dune-geometry/2.9.0-4/dune-geometry_2.9.0.orig.tar.xz"
orig_sources[dune-uggrid]="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/dune-uggrid/2.9.0-2build2/dune-uggrid_2.9.0.orig.tar.xz"
orig_sources[dune-grid]="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/dune-grid/2.9.0-3build1/dune-grid_2.9.0.orig.tar.xz"
orig_sources[dune-localfunctions]="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/dune-localfunctions/2.9.0-2ubuntu3/dune-localfunctions_2.9.0.orig.tar.xz"

declare -A packaging_sources
packaging_sources[dune-geometry]="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/dune-geometry/2.9.0-4/dune-geometry_2.9.0-4.debian.tar.xz"
packaging_sources[dune-uggrid]="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/dune-uggrid/2.9.0-2build2/dune-uggrid_2.9.0-2build2.debian.tar.xz"
packaging_sources[dune-grid]="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/dune-grid/2.9.0-3build1/dune-grid_2.9.0-3build1.debian.tar.xz"
packaging_sources[dune-localfunctions]="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/dune-localfunctions/2.9.0-2ubuntu3/dune-localfunctions_2.9.0-2ubuntu3.debian.tar.xz"

MODULE_LIST="dune-common dune-istl dune-geometry dune-uggrid dune-grid dune-localfunctions"
for module in ${MODULE_LIST}
do
  su builder -c "wget ${orig_sources[$module]}"
  if ! test -d $ROOT/packaging/$module
  then
    su builder -c "wget ${packaging_sources[$module]}"
  fi
  mkdir $module
  chown builder $module
  pushd $module
  if grep -q .tar.gz <<< ${orig_sources[$module]}
  then
    su builder -c "tar zxvf ../`basename ${orig_sources[$module]}` --strip-components=1 "
  else
    su builder -c "tar Jxvf ../`basename ${orig_sources[$module]}` --strip-components=1"
  fi
  if test -d $ROOT/packaging/$module
  then
    su builder -c "cp -r $ROOT/packaging/$module debian"
  else
    su builder -c "tar Jxvf ../`basename ${packaging_sources[$module]}`"
  fi
  version=`head -n1 debian/changelog | sed -e 's/.*(\(.*\)).*/\1/g'`
  su builder -c "dch -b -v $version-opm${OPM_VER}~$DIST -D $DIST --force-distribution --empty 'New build for opm'"
  if  grep -q .tar.gz <<< ${orig_sources[$module]}
  then
    mv ../`basename ${orig_sources[$module]}` ../${module}_${version}.orig.tar.gz
  else
    mv ../`basename ${orig_sources[$module]}` ../${module}_${version}.orig.tar.xz
  fi

  cd ..
  DEBIAN_FRONTEND=noninteractive mk-build-deps --install --remove --tool='apt-get -o Debug::pkgProblemResolver=yes --yes' $module/debian/control 
  cd $module 
  chown builder:builder * -R
  su builder -c "debuild -S -uc -us"
  su builder -c "debuild -b -uc -us"
  popd
  rm $module -R
  dpkg -i *deb 
done

popd
