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

gresource_files = ''
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

  gresource_files += '<file preprocess="xml-stripblanks" alias="fedi-@0@.xml">@1@/fedi-@0@.xml</file>\n<file preprocess="xml-stripblanks" alias="fedi-@0@-dark.xml">@1@/fedi-@0@-dark.xml</file>\n'.format(color, meson.current_build_dir())
endforeach

gresource_file = configure_file(
    input : 'gresource.xml.in',
    output : 'gresource.xml',
    configuration : {'GRESOURCE_SOURCEVIEW_STYLES_FILES': gresource_files}
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

if host_machine.system() != 'windows' and host_machine.system() != 'darwin'
    appstream_file = i18n.merge_file(
        input: meson.project_name() + '.metainfo.xml.in',
        output: meson.project_name() + '.metainfo.xml',
        po_dir: join_paths(meson.project_source_root(), 'po'),
        install: true,
        install_dir: join_paths(get_option('datadir'), 'metainfo'),
    )

    appstreamcli = find_program('appstreamcli', required: false)
    if appstreamcli.found()
        test(
            'Validate appstream file',
            appstreamcli,
            args: ['validate', '--no-net', '--explain', appstream_file],
        )
    endif
endif

manpage = configure_file(
    input : 'dev.geopjr.Tuba.1.in',
    output : 'dev.geopjr.Tuba.1',
    configuration : config
)
install_man(manpage)
