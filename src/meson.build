plug_files = files(
    'MainView.vala',
    'Plug.vala',
    'Parser.vala',
    'DateTime1.vala',
    'CurrentTimeManager.vala',
    'PantheonAccountsServicePlugin.vala',
    'Widgets/TimeZoneGrid.vala'
)

switchboard_dep = dependency('switchboard-2.0')
switchboard_plugsdir = switchboard_dep.get_pkgconfig_variable('plugsdir', define_variable: ['libdir', libdir])

shared_module(
    meson.project_name(),
    plug_files,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gio-2.0'),
        dependency('gobject-2.0'),
        dependency('granite', version: '>= 5.0.0'),
        dependency('gtk+-3.0'),
        meson.get_compiler('vala').find_library('posix'),
        switchboard_dep,
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install: true,
    install_dir : join_paths(switchboard_plugsdir, 'system')
)
