project('com.github.bleakgrey.tootle', 'vala', 'c', version: '1.0.0')

add_global_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    ],
    language: 'c',
)

libhandy_dep = dependency('libhandy-1', version: '>= 1.0', required: false)
if not libhandy_dep.found()
  libhandy = subproject(
    'libhandy',
    default_options: [
      'examples=false',
      'glade_catalog=disabled',
      'tests=false',
    ]
  )

  libhandy_dep = declare_dependency(
    dependencies: [
      libhandy.get_variable('libhandy_dep'),
      libhandy.get_variable('libhandy_vapi'),
    ]
  )
endif

config = configuration_data()
config.set('EXEC_NAME', meson.project_name())
config.set('GETTEXT_PACKAGE', meson.project_name())
config.set('RESOURCES', '/' + '/'.join(meson.project_name().split('.')) + '/' )
config.set('VERSION', meson.project_version())
config.set('PREFIX', get_option('prefix'))
config.set('NAME', 'Tootle')
config.set('WEBSITE', 'https://github.com/bleakgrey/tootle')
config.set('SUPPORT_WEBSITE', 'https://github.com/bleakgrey/tootle/issues')
config.set('COPYRIGHT', '© 2018-2020 bleak_grey')
config.set('ACCOUNT_STORE', 'FileAccountStore')

gnome = import('gnome')
i18n = import('i18n')

asresources = gnome.compile_resources(
  'as-resources', 'data/gresource.xml',
  source_dir: 'data',
  c_name: 'as'
)

sources = files(
    'src/Application.vala',
    'src/Desktop.vala',
    'src/Drawing.vala',
    'src/Html.vala',
    'src/Request.vala',
    'src/DateTime.vala',
    'src/Services/Accounts/InstanceAccount.vala',
    'src/Services/Accounts/AccountStore.vala',
    'src/Services/Accounts/FileAccountStore.vala',
    'src/Services/Accounts/IAccountListener.vala',
    'src/Services/Accounts/Mastodon/MastodonAccount.vala',
    'src/Services/Streams.vala',
    'src/Services/Settings.vala',
    'src/Services/IStreamListener.vala',
    'src/Services/Cache.vala',
    'src/Services/Network.vala',
    'src/API/Account.vala',
    'src/API/AccountField.vala',
    'src/API/Relationship.vala',
    'src/API/Mention.vala',
    'src/API/Tag.vala',
    'src/API/Status.vala',
    'src/API/Visibility.vala',
    'src/API/Notification.vala',
    'src/API/NotificationType.vala',
    'src/API/Attachment.vala',
    'src/API/Conversation.vala',
    'src/API/List.vala',
    'src/API/SearchResults.vala',
    'src/API/Entity.vala',
    'src/Widgets/Widgetizable.vala',
    'src/Widgets/Avatar.vala',
    'src/Widgets/AccountsButton.vala',
    'src/Widgets/TimelineMenu.vala',
    'src/Widgets/RichLabel.vala',
    'src/Widgets/Status.vala',
    'src/Widgets/Notification.vala',
    'src/Widgets/Conversation.vala',
    'src/Widgets/VisibilityPopover.vala',
    'src/Widgets/Attachment/Box.vala',
    'src/Widgets/Attachment/Slot.vala',
    'src/Widgets/Attachment/Picture.vala',
    'src/Widgets/AdaptiveButton.vala',
    'src/Widgets/MarkupPolicy.vala',
    'src/Widgets/MarkupView.vala',
    'src/Dialogs/ISavedWindow.vala',
    'src/Dialogs/NewAccount.vala',
    'src/Dialogs/MainWindow.vala',
    'src/Dialogs/About.vala',
    'src/Dialogs/Compose.vala',
    'src/Dialogs/Preferences.vala',
    'src/Dialogs/ListEditor.vala',
    'src/Views/Base.vala',
    'src/Views/TabbedBase.vala',
    'src/Views/Main.vala',
    'src/Views/Timeline.vala',
    'src/Views/Home.vala',
    'src/Views/Local.vala',
    'src/Views/Federated.vala',
    'src/Views/Notifications.vala',
    'src/Views/Conversations.vala',
    'src/Views/Bookmarks.vala',
    'src/Views/Thread.vala',
    'src/Views/Profile.vala',
    'src/Views/Favorites.vala',
    'src/Views/Search.vala',
    'src/Views/Hashtag.vala',
    'src/Views/Lists.vala',
    'src/Views/List.vala',
)

libsecret_dep = dependency('libsecret-1', required: false)
if not libsecret_dep.found()
    warning('Keyring support disabled. Accounts will be stored in a text file.')
else
    config.set('ACCOUNT_STORE','SecretAccountStore')
    sources += 'src/Services/Accounts/'+config.get('ACCOUNT_STORE')+'.vala'
endif

build_file = configure_file(
    input: 'src/Build.vala.in',
    output: 'Build.vala',
    configuration: config
)

executable(
    meson.project_name(),
    asresources,
    build_file,
    sources,
    dependencies: [
        dependency('gtk+-3.0', version: '>=3.22.0'),
        dependency('glib-2.0', version: '>=2.30.0'),
        dependency('gee-0.8', version: '>=0.8.5'),
        dependency('libsoup-2.4'),
        dependency('json-glib-1.0', version: '>=1.4.4'),
        dependency('libxml-2.0'),
        libhandy_dep,
        libsecret_dep,
    ],
    install: true,
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
