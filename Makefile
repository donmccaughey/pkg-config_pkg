TMP ?= $(abspath tmp)

version := 0.29.2
revision := 1
configure_flags := --with-internal-glib
identity_name := Donald McCaughey

.SECONDEXPANSION :

.PHONY : all
all : pkg-config-$(version).pkg


.PHONY : clean
clean :
	-rm -f pkg-config-*.pkg
	-rm -rf $(TMP)


##### dist ##########
dist_sources := $(shell find dist -type f \! -name .DS_Store)

$(TMP)/install/usr/local/bin/pkg-config : $(TMP)/build/pkg-config | $(TMP)/install
	cd $(TMP)/build && $(MAKE) DESTDIR=$(TMP)/install install

$(TMP)/build/pkg-config : $(TMP)/build/config.status $(dist_sources)
	cd $(TMP)/build && $(MAKE)

$(TMP)/build/config.status : dist/configure | $(TMP)/build
	cd $(TMP)/build && sh $(abspath $<) $(configure_flags)

$(TMP)/build \
$(TMP)/install :
	mkdir -p $@


##### pkg ##########

$(TMP)/pkg-config-$(version).pkg : \
        $(TMP)/install/usr/local/bin/pkg-config \
        $(TMP)/install/etc/paths.d/pkg-config.path
	pkgbuild \
        --root $(TMP)/install \
        --identifier cc.donm.pkg.pkg-config \
        --ownership recommended \
        --version $(version) \
        $@

$(TMP)/install/etc/paths.d/pkg-config.path : pkg-config.path | $(TMP)/install/etc/paths.d
	cp $< $@

$(TMP)/install/etc/paths.d :
	mkdir -p $@


##### product ##########

pkg-config-$(version).pkg : \
        $(TMP)/pkg-config-$(version).pkg \
        $(TMP)/distribution.xml \
        $(TMP)/resources/background.png \
        $(TMP)/resources/license.html \
        $(TMP)/resources/welcome.html
	productbuild \
        --distribution $(TMP)/distribution.xml \
        --resources $(TMP)/resources \
        --package-path $(TMP) \
        --version $(version)-r$(revision) \
        --sign '$(identity_name)' \
        $@

$(TMP)/distribution.xml \
$(TMP)/resources/welcome.html : $(TMP)/% : % | $$(dir $$@)
	sed -e s/{{version}}/$(version)/g $< > $@

$(TMP)/resources/background.png \
$(TMP)/resources/license.html : $(TMP)/% : % | $(TMP)/resources
	cp $< $@

$(TMP) \
$(TMP)/resources :
	mkdir -p $@

