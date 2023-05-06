project(
    'dev.geopjr.Tuba',
    ['c', 'vala'],
    version: '0.2.0',
    meson_version: '>= 0.56.0',
    default_options: [
        'warning_level=2',
        'werror=false',
    ],
)

devel = get_option('devel')
distro = get_option('distro')

# Setup configuration file, accessed via vapi/build.vapi
config = configuration_data()
config.set_quoted('EXEC_NAME', meson.project_name())
config.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
config.set_quoted('DOMAIN', meson.project_name ())
config.set_quoted('G_LOG_DOMAIN', 'Tuba')
config.set_quoted('RESOURCES', '/' + '/'.join(meson.project_name().split('.')) + '/')
config.set_quoted('VERSION', meson.project_version())
config.set_quoted('PREFIX', get_option('prefix'))
config.set_quoted('NAME', 'Tuba')
config.set_quoted('WEBSITE', 'https://github.com/GeopJr/Tuba')
config.set_quoted('SUPPORT_WEBSITE', 'https://github.com/GeopJr/Tuba/issues')
config.set_quoted('PROFILE', devel ? 'development' : 'production')

if devel
  git = find_program('git')
  if git.found()
    branch = run_command('git', 'branch', '--show-current', check: true).stdout().strip()
    revision = run_command('git', 'rev-parse', '--short', 'HEAD', check: true).stdout().strip()
    version = '@0@-@1@'.format(branch, revision)
    config.set_quoted('VERSION', version)
  endif
endif

configure_file(output: 'config.h', configuration: config)

add_project_arguments (
  '--include','config.h',
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  language: 'c'
)

gnome = import('gnome')
i18n = import('i18n')

asresources = gnome.compile_resources(
    'as-resources',
    'data/gresource.xml',
    source_dir: 'data',
    c_name: 'as',
)

libgtk_dep = dependency('gtk4', version: '>=4.0.0', required: true)
libadwaita_dep = dependency('libadwaita-1', version: '>=1.2', required: true)
gtksourceview_dep = dependency('gtksourceview-5', required: true, version: '>=5.6.0')
libwebp_dep = dependency('libwebp', required: false)

if not libwebp_dep.found ()
  warning('WebP support might be missing, please install webp-pixbuf-loader.')
endif

if libgtk_dep.version().version_compare('>=4.8.0')
  add_project_arguments(['--define=GTK_4_8'], language: 'vala')
endif

if libgtk_dep.version().version_compare('>=4.10.0')
  add_project_arguments(['--define=GTK_4_10'], language: 'vala')
endif

if gtksourceview_dep.version().version_compare('>=5.7.1')
  add_project_arguments(['--define=GTKSOURCEVIEW_5_7_1'], language: 'vala')
endif

sources = files(
    'vapi/build.vapi',
)
subdir('src')

executable(
    meson.project_name(),
    asresources,
    sources,
    dependencies: [
        dependency('glib-2.0', version: '>=2.70'),
        dependency('gee-0.8', version: '>=0.8.5'),
        dependency('libsoup-3.0'),
        dependency('json-glib-1.0', version: '>=1.4.4'),
        dependency('libxml-2.0'),
        dependency('libsecret-1', required: true),
        gtksourceview_dep,
        libgtk_dep,
        libadwaita_dep,
    ],
    install: true,
)

subdir('data')
subdir('po')

# Distributions use their own tooling (e.g. postinst, triggers, etc)
# so it is okay if the post_install() is not run on distro builds
if not distro
  # gnome.post_install() is available since meson 0.59.0
  if meson.version().version_compare('>=0.59.0')
    gnome.post_install(
      glib_compile_schemas: true,
      gtk_update_icon_cache: true,
      update_desktop_database: true,
    )
  else
    meson.add_install_script('build-aux/meson_post_install.py')
  endif
endif
