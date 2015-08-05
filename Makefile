TMP ?= $(abspath tmp)

dist_version := 0.28
dist_configure_flags := --with-internal-glib
product_version := 1

dist_name := pkg-config
dist_dir := dist
dist_sources := $(shell find $(dist_dir) -type f \! -name .DS_Store)
dist_build_dir := $(TMP)/build
dist_build_outputs := $(dist_build_dir)/pkg-config
dist_install_dir := $(TMP)/install
dist_install_outputs := $(dist_install_dir)/usr/local/bin/pkg-config

pkg_version := $(dist_version) 
pkg := $(TMP)/$(dist_name)-$(dist_version).pkg
pkg_dist_inputs := $(dist_install_outputs)
pkg_root := $(dist_install_dir)
pkg_identifier := com.ablepear.$(dist_name)

product := $(dist_name)-$(dist_version).pkg
product_pkg_inputs := $(pkg)
product_distribution := distribution.xml
product_resource_dir := resources
product_resources := $(shell find $(product_resource_dir) -type f \! -name .DS_Store)
product_package_path_args := $(addprefix --package-path , $(dir $(product_pkg_inputs)))
product_sign := 'Able Pear Software Incorporated'


##### phony targets ##########

.PHONY : all
all : $(product)


.PHONY : clean
clean :
	-rm -f $(product)
	-rm -rf $(TMP)


##### dist ##########

$(dist_install_outputs) : $(dist_build_outputs) | $(dist_install_dir)
	cd $(dist_build_dir) && $(MAKE) DESTDIR=$(dist_install_dir) install

$(dist_build_outputs) : $(dist_build_dir)/config.status $(dist_sources) | $(dist_build_dir)
	cd $(dist_build_dir) && $(MAKE)

$(dist_build_dir)/config.status : $(dist_dir)/configure | $(dist_build_dir)
	cd $(dist_build_dir) && sh $(abspath $<) $(dist_configure_flags)

$(dist_install_dir) \
$(dist_build_dir) :
	mkdir -p $@


##### pkg ##########

$(pkg) : $(pkg_dist_inputs) | $(dir $(pkg))
	pkgbuild \
        --root $(pkg_root) \
        --identifier $(pkg_identifier) \
        --ownership recommended \
        --version $(pkg_version) \
        $@

$(dir $(pkg)) :
	mkdir -p $@


##### product ##########

$(product) : \
        $(product_pkg_inputs) \
        $(product_distribution) \
        $(product_resources) \
        | $(dir $(product))
	productbuild \
        --distribution $(product_distribution) \
        --resources $(product_resource_dir) \
        $(product_package_path_args) \
        --version $(product_version) \
        --sign $(product_sign) \
        $@

$(dir $(product)) :
	mkdir -p $@

