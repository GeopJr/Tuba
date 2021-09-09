project('com.github.bleakgrey.tootle', 'vala', 'c', version: '2.0-alpha2')

add_global_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    ],
    language: 'c',
)

config = configuration_data()
config.set('EXEC_NAME', meson.project_name())
config.set('GETTEXT_PACKAGE', meson.project_name())
config.set('RESOURCES', '/' + '/'.join(meson.project_name().split('.')) + '/' )
config.set('VERSION', meson.project_version())
config.set('PREFIX', get_option('prefix'))
config.set('NAME', 'Tootle')
config.set('WEBSITE', 'https://github.com/bleakgrey/tootle')
config.set('SUPPORT_WEBSITE', 'https://github.com/bleakgrey/tootle/issues')
config.set('COPYRIGHT', '© 2018-2021 bleak_grey')

gnome = import('gnome')
i18n = import('i18n')

asresources = gnome.compile_resources(
  'as-resources', 'data/gresource.xml',
  source_dir: 'data',
  c_name: 'as'
)

libgtk_dep = dependency('gtk4', version: '>=4.0.0', required: true)
libadwaita_dep = dependency('libadwaita-1', version: '>=1.0.0', required: true)

sources = files(
    'src/Application.vala',
    'src/Utils/Host.vala',
    'src/Utils/Html.vala',
    'src/Utils/DateTime.vala',
    'src/Services/Accounts/InstanceAccount.vala',
    'src/Services/Accounts/AccountStore.vala',
    'src/Services/Accounts/Places.vala',
    'src/Services/Accounts/SecretAccountStore.vala',
    'src/Services/Accounts/AccountHolder.vala',
    'src/Services/Accounts/Mastodon/Account.vala',
    'src/Services/Cache/AbstractCache.vala',
    'src/Services/Cache/EntityCache.vala',
    'src/Services/Cache/ImageCache.vala',
    'src/Services/Network/Network.vala',
    'src/Services/Network/Request.vala',
    'src/Services/Network/Streams.vala',
    'src/Services/Network/Streamable.vala',
    'src/Services/Settings.vala',
    'src/API/Account.vala',
    'src/API/AccountField.vala',
    'src/API/Relationship.vala',
    'src/API/Mention.vala',
    'src/API/Tag.vala',
    'src/API/Status.vala',
    'src/API/Notification.vala',
    'src/API/Attachment.vala',
    'src/API/Conversation.vala',
    'src/API/List.vala',
    'src/API/SearchResults.vala',
    'src/API/Entity.vala',
    'src/Widgets/Widgetizable.vala',
    'src/Widgets/Background.vala',
    'src/Widgets/Avatar.vala',
    'src/Widgets/RichLabel.vala',
    'src/Widgets/Status.vala',
    'src/Widgets/Notification.vala',
    'src/Widgets/Conversation.vala',
    'src/Widgets/Attachment/Box.vala',
    'src/Widgets/Attachment/Item.vala',
    'src/Widgets/Attachment/Image.vala',
    'src/Widgets/LockableToggleButton.vala',
    'src/Widgets/StatusActionButton.vala',
    'src/Widgets/RelationshipButton.vala',
    'src/Widgets/MarkupView.vala',
    'src/Dialogs/Saveable.vala',
    'src/Dialogs/NewAccount.vala',
    'src/Dialogs/MainWindow.vala',
    'src/Dialogs/Preferences.vala',
    'src/Dialogs/ListEditor.vala',
    'src/Dialogs/Composer/Dialog.vala',
    'src/Dialogs/Composer/Page.vala',
    'src/Dialogs/Composer/EditorPage.vala',
    'src/Dialogs/Composer/AttachmentsPage.vala',
    'src/Dialogs/Composer/PollPage.vala',
    'src/Views/Base.vala',
    'src/Views/ContentBase.vala',
    'src/Views/TabbedBase.vala',
    'src/Views/Sidebar.vala',
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
        dependency('glib-2.0', version: '>=2.30.0'),
        dependency('gee-0.8', version: '>=0.8.5'),
        dependency('libsoup-2.4'),
        dependency('json-glib-1.0', version: '>=1.4.4'),
        dependency('libxml-2.0'),
        dependency('libsecret-1', required: true),
        libgtk_dep,
        libadwaita_dep,
    ],
    install: true,
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
