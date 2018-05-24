# Switchboard Date & Time Plug
[![l10n](https://l10n.elementary.io/widgets/switchboard/switchboard-plug-datetime/svg-badge.svg)](https://l10n.elementary.io/projects/switchboard/switchboard-plug-datetime)

## Building and Installation

You'll need the following dependencies:

* libgranite-dev
* libswitchboard-2.0-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install

## Regenerate the Translation.vala

To regenerate the `Translation.vala` file containing the list of all the timezone names ready to parse by gettext, set the `regenerate_translation` option to `true`

    cd build
    meson configure -Dregenerate_translation=true

You'll then need to install the plug, run switchboard and open the plug. The new `Translation.vala` file will be ready in your Home folder.
