TMP ?= $(abspath tmp)

version := 0.28
installer_version := 1
configure_flags := --with-internal-glib


##### phony targets ##########

.PHONY : all
all : pkg-config-$(version).pkg


.PHONY : clean
clean :
	-rm -f pkg-config-$(version).pkg
	-rm -rf $(TMP)


##### dist ##########
dist_sources := $(shell find dist -type f \! -name .DS_Store)

$(TMP)/install/usr/local/bin/pkg-config : $(TMP)/build/pkg-config | $(TMP)/install
	cd $(TMP)/build && $(MAKE) DESTDIR=$(TMP)/install install

$(TMP)/build/pkg-config : $(TMP)/build/config.status $(dist_sources)
	cd $(TMP)/build && $(MAKE)

$(TMP)/build/config.status : dist/configure | $(TMP)/build
	cd $(TMP)/build && sh $(abspath $<) $(configure_flags)

$(TMP)/install \
$(TMP)/build :
	mkdir -p $@


##### pkg ##########

$(TMP)/pkg-config-$(version).pkg : $(TMP)/install/usr/local/bin/pkg-config
	pkgbuild \
        --root $(TMP)/install \
        --identifier com.ablepear.pkg-config \
        --ownership recommended \
        --version $(version) \
        $@


##### product ##########

pkg-config-$(version).pkg : \
        $(TMP)/pkg-config-$(version).pkg \
        distribution.xml \
        resources/background.png \
        resources/license.html \
        resources/welcome.html
	productbuild \
        --distribution distribution.xml \
        --resources resources \
        --package-path $(TMP) \
        --version $(installer_version) \
        --sign 'Able Pear Software Incorporated' \
        $@

