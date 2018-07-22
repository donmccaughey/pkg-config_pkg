TMP ?= $(abspath tmp)

version := 0.29.2
revision := 1
configure_flags := --with-internal-glib
identity_name := Donald McCaughey

date := $(shell date '+%Y-%m-%d')
macos:=$(shell \
	system_profiler -detailLevel mini SPSoftwareDataType \
	| grep 'System Version:' \
	| awk -F ' ' '{print $$4}' \
	)
xcode:=$(shell \
	system_profiler -detailLevel mini SPDeveloperToolsDataType \
	| grep 'Version:' \
	| awk -F ' ' '{print $$2}' \
	)


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

$(TMP)/build/config.status : dist/configure | $$(dir $$@)
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

$(TMP)/install/etc/paths.d/pkg-config.path : pkg-config.path | $$(dir $$@)
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
	sed \
		-e s/{{date}}/$(date)/g \
		-e s/{{macos}}/$(macos)/g \
		-e s/{{revision}}/$(revision)/g \
		-e s/{{version}}/$(version)/g \
		-e s/{{xcode}}/$(xcode)/g \
		$< > $@

$(TMP)/resources/background.png \
$(TMP)/resources/license.html : $(TMP)/% : % | $$(dir $$@)
	cp $< $@

$(TMP) \
$(TMP)/resources :
	mkdir -p $@

