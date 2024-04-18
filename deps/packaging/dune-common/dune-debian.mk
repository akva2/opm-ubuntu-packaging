include /usr/share/dpkg/architecture.mk
include /usr/share/dpkg/pkg-info.mk

DUNE_DEBIAN_ENV ?= /usr/share/dune/dune-debian.env

include $(DUNE_DEBIAN_ENV)

EMPTY :=
SPACE := $(EMPTY) $(EMPTY)

DUNE_CTEST ?= /usr/bin/dune-ctest

DUNE_DEBIAN_CMAKE_FLAGS = -DBUILD_SHARED_LIBS=1

DUNE_DEBIAN_SHLIB = $(subst ~,.,lib$(DEB_SOURCE)-$(DEB_VERSION_UPSTREAM))

DUNE_DOC_BUILT_USING_PACKAGES = doxygen
DUNE_DOC_BUILT_USING = $(shell dpkg-query -f '$${source:Package} (= $${source:Version})' -W $(DUNE_DOC_BUILT_USING_PACKAGES))

ifeq ($(DEB_HOST_ARCH_CPU),i386)
  DEB_CXXFLAGS_MAINT_APPEND += -ffloat-store
endif

ifeq ($(DUNE_TEST_LABELS),)
  DUNE_TEST_BUILD_TARGETS=build_tests
  DUNE_TEST_CTEST_LABELS=
else
  DUNE_TEST_BUILD_TARGETS=$(foreach label,$(DUNE_TEST_LABELS),build_$(label)_tests)
  DUNE_TEST_CTEST_LABELS=--label-regex '^$(subst $(SPACE),|,$(DUNE_TEST_LABELS))$$'
endif

export DEB_CXXFLAGS_MAINT_APPEND

override_dh_auto_configure:
	dh_auto_configure -- $(DUNE_DEBIAN_CMAKE_FLAGS)

override_dh_auto_test:
	dh_auto_build -- $(DUNE_TEST_BUILD_TARGETS)
	cd build; PATH=$(CURDIR)/debian/tmp-test:$$PATH $(DUNE_CTEST) $(DUNE_TEST_CTEST_LABELS)

override_dh_gencontrol:
	dh_gencontrol -- -Vdune:shared-library='$(DUNE_DEBIAN_SHLIB)' -Vdune:doc:Built-Using='$(DUNE_DOC_BUILT_USING)'

override_dh_makeshlibs:
	dh_makeshlibs --version-info='$(DUNE_DEBIAN_SHLIB)'
