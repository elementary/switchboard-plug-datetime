plug_files = files(
    'MainView.vala',
    'Plug.vala',
    'Parser.vala',
    'DateTime1.vala',
    'CurrentTimeManager.vala',
    'GreeterAccountsServicePlugin.vala',
    'Widgets/TZPopover.vala',
    'Widgets/TimeZoneButton.vala'
)

switchboard_dep = dependency('switchboard-2.0')

shared_module(
    meson.project_name(),
    plug_files,
    plug_resources,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gio-2.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        meson.get_compiler('vala').find_library('posix'),
        switchboard_dep,
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install: true,
    install_dir : join_paths(switchboard_dep.get_pkgconfig_variable('plugsdir'), 'system')
)
