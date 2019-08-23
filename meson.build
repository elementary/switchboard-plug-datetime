project(
    'datetime',
    'vala', 'c',
    version: '2.1.6'
)

gettext_name = meson.project_name() + '-plug'
gnome = import('gnome')
i18n = import('i18n')

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    language:'c'
)

if (get_option('regenerate_translation'))
    add_project_arguments(
        '--define=GENERATE',
        language:'vala'
    )
endif

plug_resources = gnome.compile_resources(
    'plug_resources',
    'data/datetime.gresource.xml',
    source_dir: 'data'
)

subdir('data')
subdir('src')
subdir('po')
