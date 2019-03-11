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
    'src/Desktop.vala',
    'src/Drawing.vala',
    'src/Html.vala',
    'src/Settings.vala',
    'src/Accounts.vala',
    'src/ImageCache.vala',
    'src/Network.vala',
    'src/Watchlist.vala',
    'src/Notificator.vala',
    'src/InstanceAccount.vala',
    'src/API/Account.vala',
    'src/API/Relationship.vala',
    'src/API/Mention.vala',
    'src/API/Tag.vala',
    'src/API/Status.vala',
    'src/API/StatusVisibility.vala',
    'src/API/Notification.vala',
    'src/API/NotificationType.vala',
    'src/API/Attachment.vala',
    'src/Widgets/AlignedLabel.vala',
    'src/Widgets/RichLabel.vala',
    'src/Widgets/ImageToggleButton.vala',
    'src/Widgets/AccountsButton.vala',
    'src/Widgets/Status.vala',
    'src/Widgets/Account.vala',
    'src/Widgets/Notification.vala',
    'src/Widgets/ImageAttachment.vala',
    'src/Widgets/AttachmentGrid.vala',
    'src/Dialogs/ISavedWindow.vala',
    'src/Dialogs/MainWindow.vala',
    'src/Dialogs/NewAccount.vala',
    'src/Dialogs/Compose.vala',
    'src/Dialogs/Preferences.vala',
    'src/Dialogs/WatchlistEditor.vala',
    'src/Views/Abstract.vala',
    'src/Views/Timeline.vala',
    'src/Views/Home.vala',
    'src/Views/Local.vala',
    'src/Views/Federated.vala',
    'src/Views/Notifications.vala',
    'src/Views/Direct.vala',
    'src/Views/ExpandedStatus.vala',
    'src/Views/Profile.vala',
    'src/Views/Followers.vala',
    'src/Views/Following.vala',
    'src/Views/Favorites.vala',
    'src/Views/Search.vala',
    'src/Views/Hashtag.vala',
    dependencies: [
        dependency('gtk+-3.0', version: '>=3.22.0'),
        dependency('glib-2.0', version: '>=2.30.0'),
        dependency('gee-0.8', version: '>=0.8.5'),
        dependency('granite', version: '>=5.2.0'),
        dependency('json-glib-1.0'),
        dependency('libsoup-2.4')
    ],
    install: true
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
