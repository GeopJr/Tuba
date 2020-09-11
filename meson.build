project('com.github.bleakgrey.tootle', 'vala', 'c', version: '1.0.0-alpha2')

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

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    ],
    language: 'c',
)

asresources = gnome.compile_resources(
  'as-resources', 'data/gresource.xml',
  source_dir: 'data',
  c_name: 'as'
)

build_file = configure_file(
	input: 'src/Build.vala',
	output: 'Build.vala',
	configuration: config
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

executable(
    meson.project_name(),
    asresources,
    build_file,
    'src/Application.vala',
    'src/Desktop.vala',
    'src/Drawing.vala',
    'src/Html.vala',
    'src/Request.vala',
    'src/DateTime.vala',
    'src/InstanceAccount.vala',
    'src/Services/Streams.vala',
    'src/Services/Settings.vala',
    'src/Services/Accounts.vala',
    'src/Services/IAccountListener.vala',
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
    'src/Dialogs/ISavedWindow.vala',
    'src/Dialogs/NewAccount.vala',
    'src/Dialogs/MainWindow.vala',
    'src/Dialogs/About.vala',
    'src/Dialogs/Compose.vala',
    'src/Dialogs/Preferences.vala',
    'src/Dialogs/ListEditor.vala',
    'src/Views/Base.vala',
    'src/Views/Timeline.vala',
    'src/Views/Home.vala',
    'src/Views/Local.vala',
    'src/Views/Federated.vala',
    'src/Views/Notifications.vala',
    'src/Views/Conversations.vala',
    'src/Views/Bookmarks.vala',
    'src/Views/ExpandedStatus.vala',
    'src/Views/Profile.vala',
    'src/Views/Favorites.vala',
    'src/Views/Search.vala',
    'src/Views/Hashtag.vala',
    'src/Views/Lists.vala',
    'src/Views/List.vala',
    dependencies: [
        dependency('gtk+-3.0', version: '>=3.22.0'),
        dependency('glib-2.0', version: '>=2.30.0'),
        dependency('gee-0.8', version: '>=0.8.5'),
        dependency('libsoup-2.4'),
        dependency('json-glib-1.0', version: '>=1.4.4'),
        libhandy_dep,
    ],
    install: true,
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
