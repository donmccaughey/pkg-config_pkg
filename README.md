pkg-config 0.29.2 for macOS
===========================

This project builds a signed universal macOS installer package for
[`pkg-config`][1], a helper tool used when compiling applications and
libraries. It contains the source distribution for `pkg-config` 0.29.2.

[1]: http://www.freedesktop.org/wiki/Software/pkg-config/ "pkg-config"

## Building
The [`Makefile`][2] in the project root directory builds the installer package.
The following makefile variables can be set from the command line:

- `APP_SIGNING_ID`: The name of the 
    [Apple _Developer ID Application_ certificate][3] used to sign the 
    `nginx` executable.  The certificate must be installed on the build 
    machine's Keychain.  Defaults to "Developer ID Application: Donald 
    McCaughey" if not specified.
-- `INSTALLER_SIGNING_ID`: The name of the 
    [Apple _Developer ID Installer_ certificate][3] used to sign the 
    installer.  The certificate must be installed on the build machine's
    Keychain.  Defaults to "Developer ID Installer: Donald McCaughey" if 
    not specified.
- `TMP`: The name of the directory for intermediate files.  Defaults to 
    "`./tmp`" if not specified.

[2]: https://github.com/donmccaughey/pkg-config_pkg/blob/master/Makefile
[3]: https://developer.apple.com/account/resources/certificates/list

To build and sign the executable and installer, run:

        $ make [APP_SIGNING_ID="<cert name 1>"] [INSTALLER_SIGNING_ID="<cert name 2>"] [TMP="<build dir>"]

Intermediate files are generated in the temp directory; the signed installer 
package is written into the project root with the name `pkg-config-0.29.2.pkg`.  

To remove all generated files (including the signed installer), run:

        $ make clean

## License

The installer and related scripts are copyright (c) 2018 Don McCaughey.
`pkg-config` and the installer are distributed under the GNU General Public 
License, version 2.  See the LICENSE file for details.

