icons_dir = join_paths(get_option('datadir'), 'icons', 'hicolor')
scalable_dir = join_paths(icons_dir, 'scalable', 'apps')
symbolic_dir = join_paths(icons_dir, 'symbolic', 'apps')

icon = 'color.svg'
if get_option('devel')
  icon = 'color-nightly.svg'
endif

install_data(
    join_paths('icons', icon),
    install_dir: scalable_dir,
    rename: meson.project_name() + '.svg',
)
install_data(
    join_paths('icons', 'symbolic.svg'),
    install_dir: symbolic_dir,
    rename: meson.project_name() + '-symbolic.svg',
)

install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(
        get_option('prefix'),
        get_option('datadir'),
        'glib-2.0',
        'schemas',
    ),
)

syntax_colors = ['blue', 'teal', 'green', 'yellow', 'orange', 'red', 'pink', 'purple', 'slate']
foreach color : syntax_colors
  light = configure_file(
      input : join_paths('langs', 'fedi.xml.in'),
      output : 'fedi-' + color + '.xml',
      configuration : {'COLOR': color, 'VARIANT': '3', 'SYNTAX_VARIANT': 'light', 'OP_SYNTAX_VARIANT': 'dark', 'DARK_SUFFIX': '', 'OP_DARK_SUFFIX': '-dark'}
  )

  dark = configure_file(
      input : join_paths('langs', 'fedi.xml.in'),
      output : 'fedi-' + color + '-dark.xml',
      configuration : {'COLOR': color, 'VARIANT': '2', 'SYNTAX_VARIANT': 'dark', 'OP_SYNTAX_VARIANT': 'light', 'DARK_SUFFIX': '-dark', 'OP_DARK_SUFFIX': ''}
  )

  install_data(
    light, dark,
    install_dir: join_paths(
        get_option('prefix'),
        get_option('datadir'),
        'gtksourceview-5',
        'styles',
    ),
  )
endforeach

install_data(
    join_paths('langs', 'fedi-basic.lang'),
    install_dir: join_paths(
        get_option('prefix'),
        get_option('datadir'),
        'gtksourceview-5',
        'language-specs',
    ),
)

install_data(
    join_paths('langs', 'fedi-html.lang'),
    install_dir: join_paths(
        get_option('prefix'),
        get_option('datadir'),
        'gtksourceview-5',
        'language-specs',
    ),
)

install_data(
    join_paths('langs', 'fedi-markdown.lang'),
    install_dir: join_paths(
        get_option('prefix'),
        get_option('datadir'),
        'gtksourceview-5',
        'language-specs',
    ),
)

desktop_file = i18n.merge_file(
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.project_source_root(), 'po'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications'),
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
    test('Validate desktop file', desktop_utils, args: [desktop_file])
endif

configure_file(
    input: meson.project_name() + '.service.in',
    output: meson.project_name() + '.service',
    configuration: config,
    install: true,
    install_dir: join_paths(
        get_option('datadir'),
       'dbus-1',
       'services',
    ),
)

if host_machine.system() != 'windows' and host_machine.system() != 'darwin'
    appstream_file = i18n.merge_file(
        input: meson.project_name() + '.metainfo.xml.in',
        output: meson.project_name() + '.metainfo.xml',
        po_dir: join_paths(meson.project_source_root(), 'po'),
        install: true,
        install_dir: join_paths(get_option('datadir'), 'metainfo'),
    )

    appstream_util = find_program('appstream-util', required: false)
    if appstream_util.found()
        test(
            'Validate appstream file',
            appstream_util,
            args: ['validate-relax', '--nonet', appstream_file],
        )
    endif
endif

manpage = configure_file(
    input : 'dev.geopjr.Tuba.1.in',
    output : 'dev.geopjr.Tuba.1',
    configuration : config
)
install_man(manpage)
