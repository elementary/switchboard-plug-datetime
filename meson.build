project(
    'datetime',
    'vala', 'c',
    version: '0.1.3'
)

gettext_name = meson.project_name() + '-plug'
gnome = import('gnome')
i18n = import('i18n')

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
    'data/images.gresource.xml',
    source_dir: 'data'
)

subdir('src')
subdir('po')
