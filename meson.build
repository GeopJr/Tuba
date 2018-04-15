project('com.github.bleakgrey.tootle', 'vala', 'c')

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name())
    ],
    language: 'c',
)

asresources = gnome.compile_resources(
  'as-resources', 'data/' + meson.project_name() + '.gresource.xml',
  source_dir: 'data',
  c_name: 'as'
)

executable(
    meson.project_name(),
    asresources,
    'src/Application.vala',
    'src/Settings.vala',
    'src/MainWindow.vala',
    'src/AccountManager.vala',
    'src/NetManager.vala',
    'src/CacheManager.vala',
    'src/API/Account.vala',
    'src/API/Status.vala',
    'src/API/StatusVisibility.vala',
    'src/Widgets/AlignedLabel.vala',
    'src/Widgets/AccountsButton.vala',
    'src/Widgets/StatusWidget.vala',
    'src/Dialogs/DialogToot.vala',
    'src/Views/AbstractView.vala',
    'src/Views/AddAccountView.vala',
    'src/Views/HomeView.vala',
    'src/Views/LocalView.vala',
    'src/Views/FederatedView.vala',
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('glib-2.0', version: '>=2.30.0'),
        dependency('granite'),
        dependency('json-glib-1.0'),
        dependency('libsoup-2.4')
    ],
    install: true
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
