INSTALLER_SIGNING_ID ?= Developer ID Installer: Donald McCaughey
TMP ?= $(abspath tmp)

version := 0.29.2
revision := 2
archs := arm64 x86_64


.SECONDEXPANSION :


.PHONY : all
all : pkg-config-$(version).pkg


.PHONY : clean
clean :
	-rm -f pkg-config-*.pkg
	-rm -rf $(TMP)


.PHONY : check
check :
	test "$(shell lipo -archs $(TMP)/install/usr/local/bin/pkg-config)" = "x86_64 arm64"


##### compilation flags ##########

arch_flags = $(patsubst %,-arch %,$(archs))

CFLAGS += $(arch_flags)


##### dist ##########

dist_sources := $(shell find dist -type f \! -name .DS_Store)

$(TMP)/install/usr/local/bin/pkg-config : $(TMP)/build/pkg-config | $(TMP)/install
	cd $(TMP)/build && $(MAKE) DESTDIR=$(TMP)/install install

$(TMP)/build/pkg-config : $(TMP)/build/config.status $(dist_sources)
	cd $(TMP)/build && $(MAKE)

$(TMP)/build/config.status : dist/configure | $$(dir $$@)
	cd $(TMP)/build \
		&& sh $(abspath $<) \
			CFLAGS='$(CFLAGS)' \
			--disable-silent-rules \
			--with-internal-glib

$(TMP)/build \
$(TMP)/install :
	mkdir -p $@


##### pkg ##########

$(TMP)/pkg-config.pkg : \
        $(TMP)/install/etc/paths.d/pkg-config.path \
        $(TMP)/install/usr/local/bin/pkg-config \
		$(TMP)/install/usr/local/bin/uninstall-pkg-config
	pkgbuild \
        --root $(TMP)/install \
        --identifier cc.donm.pkg.pkg-config \
        --ownership recommended \
        --version $(version) \
        $@

$(TMP)/install/etc/paths.d/pkg-config.path : pkg-config.path | $$(dir $$@)
	cp $< $@

$(TMP)/install/usr/local/bin/uninstall-pkg-config : \
		uninstall-pkg-config \
		$(TMP)/install/usr/local/bin/pkg-config \
		| $$(dir $$@)
	cp $< $@
	cd $(TMP)/install && find . -type f \! -name .DS_STORE | sort >> $@
	sed -e 's/^\./rm -f /g' -i '' $@
	chmod a+x $@

$(TMP)/install/etc/paths.d \
$(TMP)/install/usr/local/bin :
	mkdir -p $@


##### product ##########

arch_list := $(shell printf '%s' "$(archs)" | sed "s/ / and /g")
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

pkg-config-$(version).pkg : \
        $(TMP)/pkg-config.pkg \
		$(TMP)/build-report.txt \
        $(TMP)/distribution.xml \
        $(TMP)/resources/background.png \
		$(TMP)/resources/background-darkAqua.png \
        $(TMP)/resources/license.html \
        $(TMP)/resources/welcome.html
	productbuild \
        --distribution $(TMP)/distribution.xml \
        --resources $(TMP)/resources \
        --package-path $(TMP) \
        --version v$(version)-r$(revision) \
        --sign '$(INSTALLER_SIGNING_ID)' \
        $@

$(TMP)/build-report.txt : | $$(dir $$@)
	printf 'Build Date: %s\n' "$(date)" > $@
	printf 'Software Version: %s\n' "$(version)" >> $@
	printf 'Architectures: %s\n' "$(arch_list)" >> $@
	printf 'Installer Revision: %s\n' "$(revision)" >> $@
	printf 'macOS Version: %s\n' "$(macos)" >> $@
	printf 'Xcode Version: %s\n' "$(xcode)" >> $@
	printf 'Tag Version: v%s-r%s\n' "$(version)" "$(revision)" >> $@
	printf 'INSTALLER_SIGNING_ID: %s\n' "$(INSTALLER_SIGNING_ID)" >> $@
	printf 'TMP directory: %s\n' "$(TMP)" >> $@
	printf 'CFLAGS: %s\n' "$(CFLAGS)" >> $@
	printf 'Release Title: pkg-config %s for macOS rev %s\n' "$(version)" "$(revision)" >> $@
	printf 'Description: A signed macOS installer package for `pkg-config` %s.\n' "$(version)" >> $@

$(TMP)/distribution.xml \
$(TMP)/resources/welcome.html : $(TMP)/% : % | $$(dir $$@)
	sed \
		-e 's/{{arch_list}}/$(arch_list)/g' \
		-e 's/{{date}}/$(date)/g' \
		-e 's/{{macos}}/$(macos)/g' \
		-e 's/{{revision}}/$(revision)/g' \
		-e 's/{{version}}/$(version)/g' \
		-e 's/{{xcode}}/$(xcode)/g' \
		$< > $@

$(TMP)/resources/background.png \
$(TMP)/resources/background-darkAqua.png \
$(TMP)/resources/license.html : $(TMP)/% : % | $$(dir $$@)
	cp $< $@

$(TMP) \
$(TMP)/resources :
	mkdir -p $@

