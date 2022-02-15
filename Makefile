APP_SIGNING_ID ?= Developer ID Application: Donald McCaughey
INSTALLER_SIGNING_ID ?= Developer ID Installer: Donald McCaughey
NOTARIZATION_KEYCHAIN_PROFILE ?= Donald McCaughey
TMP ?= $(abspath tmp)

version := 0.29.2
revision := 3
archs := arm64 x86_64

rev := $(if $(patsubst 1,,$(revision)),-r$(revision),)
ver := $(version)$(rev)


.SECONDEXPANSION :


.PHONY : signed-package
signed-package : $(TMP)/pkg-config-$(ver)-unnotarized.pkg


.PHONY : notarize
notarize : pkg-config-$(ver).pkg


.PHONY : clean
clean :
	-rm -f pkg-config-*.pkg
	-rm -rf $(TMP)


.PHONY : check
check :
	test "$(shell lipo -archs $(TMP)/libiconv/install/usr/local/lib/libiconv.a)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/pkg-config/install/usr/local/bin/pkg-config)" = "x86_64 arm64"
	test "$(shell ./tools/dylibs --no-sys-libs --count $(TMP)/pkg-config/install/usr/local/bin/pkg-config) dylibs" = "0 dylibs"
	codesign --verify --strict $(TMP)/pkg-config/install/usr/local/bin/pkg-config
	pkgutil --check-signature pkg-config-$(ver).pkg
	spctl --assess --type install pkg-config-$(ver).pkg
	xcrun stapler validate pkg-config-$(ver).pkg


.PHONY : libiconv
libiconv : \
			$(TMP)/libiconv/install/usr/local/include/iconv.h \
			$(TMP)/libiconv/install/usr/local/lib/libiconv.a


##### compilation flags ##########

arch_flags = $(patsubst %,-arch %,$(archs))

CFLAGS += $(arch_flags)


##### libiconv ##########

libiconv_config_options := \
			--disable-shared \
			CFLAGS='$(CFLAGS)'

libiconv_sources := $(shell find libiconv -type f \! -name .DS_Store)

$(TMP)/libiconv/install/usr/local/include/iconv.h \
$(TMP)/libiconv/install/usr/local/lib/libiconv.a : $(TMP)/libiconv/installed.stamp.txt
	@:

$(TMP)/libiconv/installed.stamp.txt : \
			$(TMP)/libiconv/build/include/iconv.h \
			$(TMP)/libiconv/build/lib/.libs/libiconv.a \
			| $$(dir $$@)
	cd $(TMP)/libiconv/build && $(MAKE) DESTDIR=$(TMP)/libiconv/install install
	date > $@

$(TMP)/libiconv/build/include/iconv.h \
$(TMP)/libiconv/build/lib/.libs/libiconv.a : $(TMP)/libiconv/built.stamp.txt | $$(dir $$@)
	@:

$(TMP)/libiconv/built.stamp.txt : $(TMP)/libiconv/configured.stamp.txt | $$(dir $$@)
	cd $(TMP)/libiconv/build && $(MAKE)
	date > $@

$(TMP)/libiconv/configured.stamp.txt : $(libiconv_sources) | $(TMP)/libiconv/build
	cd $(TMP)/libiconv/build \
			&& $(abspath libiconv/configure) $(libiconv_config_options)
	date > $@

$(TMP)/libiconv \
$(TMP)/libiconv/build \
$(TMP)/libiconv/install :
	mkdir -p $@


##### pkg-config ##########

pkg-config_config_options := \
			--disable-silent-rules \
			--disable-host-tool \
			--with-internal-glib \
			CFLAGS='$(CFLAGS) -I $(TMP)/libiconv/install/usr/local/include' \
			LDFLAGS='$(LDFLAGS) -L$(TMP)/libiconv/install/usr/local/lib'

pkg-config_sources := $(shell find pkg-config -type f \! -name .DS_Store)

$(TMP)/pkg-config/install/usr/local/bin/pkg-config : $(TMP)/pkg-config/build/pkg-config | $(TMP)/pkg-config/install
	cd $(TMP)/pkg-config/build && $(MAKE) DESTDIR=$(TMP)/pkg-config/install install
	xcrun codesign \
		--sign "$(APP_SIGNING_ID)" \
		--options runtime \
		$@

$(TMP)/pkg-config/build/pkg-config : $(TMP)/pkg-config/build/config.status $(pkg-config_sources)
	cd $(TMP)/pkg-config/build && $(MAKE)

$(TMP)/pkg-config/build/config.status : \
			pkg-config/configure \
			$(TMP)/libiconv/install/usr/local/include/iconv.h \
			$(TMP)/libiconv/install/usr/local/lib/libiconv.a \
			| $$(dir $$@)
	cd $(TMP)/pkg-config/build \
		&& sh $(abspath $<) $(pkg-config_config_options)

$(TMP)/pkg-config/build \
$(TMP)/pkg-config/install :
	mkdir -p $@


##### pkg ##########

$(TMP)/pkg-config.pkg : \
		$(TMP)/pkg-config/install/usr/local/bin/uninstall-pkg-config
	pkgbuild \
        --root $(TMP)/pkg-config/install \
        --identifier cc.donm.pkg.pkg-config \
        --ownership recommended \
        --version $(version) \
        $@

$(TMP)/pkg-config/install/etc/paths.d/pkg-config.path : pkg-config.path | $$(dir $$@)
	cp $< $@

$(TMP)/pkg-config/install/usr/local/bin/uninstall-pkg-config : \
		uninstall-pkg-config \
        $(TMP)/pkg-config/install/etc/paths.d/pkg-config.path \
		$(TMP)/pkg-config/install/usr/local/bin/pkg-config \
		| $$(dir $$@)
	cp $< $@
	cd $(TMP)/pkg-config/install && find . -type f \! -name .DS_STORE | sort >> $@
	sed -e 's/^\./rm -f /g' -i '' $@
	chmod a+x $@

$(TMP)/pkg-config/install/etc/paths.d \
$(TMP)/pkg-config/install/usr/local/bin :
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

$(TMP)/pkg-config-$(ver)-unnotarized.pkg : \
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
	printf 'Installer Revision: %s\n' "$(revision)" >> $@
	printf 'Architectures: %s\n' "$(arch_list)" >> $@
	printf 'macOS Version: %s\n' "$(macos)" >> $@
	printf 'Xcode Version: %s\n' "$(xcode)" >> $@
	printf 'APP_SIGNING_ID: %s\n' "$(APP_SIGNING_ID)" >> $@
	printf 'INSTALLER_SIGNING_ID: %s\n' "$(INSTALLER_SIGNING_ID)" >> $@
	printf 'NOTARIZATION_KEYCHAIN_PROFILE: %s\n' "$(NOTARIZATION_KEYCHAIN_PROFILE)" >> $@
	printf 'TMP directory: %s\n' "$(TMP)" >> $@
	printf 'CFLAGS: %s\n' "$(CFLAGS)" >> $@
	printf 'Tag: v%s-r%s\n' "$(version)" "$(revision)" >> $@
	printf 'Tag Title: pkg-config %s for macOS rev %s\n' "$(version)" "$(revision)" >> $@
	printf 'Tag Message: A signed and notarized universal installer package for `pkg-config` %s.\n' "$(version)" >> $@

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


##### notarization ##########

$(TMP)/submit-log.json : $(TMP)/pkg-config-$(ver)-unnotarized.pkg | $$(dir $$@)
	xcrun notarytool submit $< \
		--keychain-profile "$(NOTARIZATION_KEYCHAIN_PROFILE)" \
		--output-format json \
		--wait \
		> $@

$(TMP)/submission-id.txt : $(TMP)/submit-log.json | $$(dir $$@)
	jq --raw-output '.id' < $< > $@

$(TMP)/notarization-log.json : $(TMP)/submission-id.txt | $$(dir $$@)
	xcrun notarytool log "$$(<$<)" \
		--keychain-profile "$(NOTARIZATION_KEYCHAIN_PROFILE)" \
		$@

$(TMP)/notarized.stamp.txt : $(TMP)/notarization-log.json | $$(dir $$@)
	test "$$(jq --raw-output '.status' < $<)" = "Accepted"
	date > $@

pkg-config-$(ver).pkg : $(TMP)/pkg-config-$(ver)-unnotarized.pkg $(TMP)/notarized.stamp.txt
	cp $< $@
	xcrun stapler staple $@

