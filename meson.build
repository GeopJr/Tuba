project('com.github.bleakgrey.tootle', 'vala', 'c')

gnome = import('gnome')
i18n = import('i18n')

#add_project_arguments(['--disable-warnings', '-g', '-X', '-rdynamic'], language: 'vala')
add_project_arguments(['-g', '-rdynamic', '-export-dynamic'], language: 'c')

add_global_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name())
    ],
    language: 'c',
)

asresources = gnome.compile_resources(
  'as-resources', 'data/gresource.xml',
  source_dir: 'data',
  c_name: 'as'
)

executable(
    meson.project_name(),
    asresources,
    
    'src/Stacktrace.vala', #TODO: move into a separate lib
    
    'src/Build.vala',
    'src/Application.vala',
    'src/Desktop.vala',
    'src/Drawing.vala',
    'src/Html.vala',
    'src/Utils.vala',
    'src/Request.vala',
    'src/InstanceAccount.vala',
    'src/Services/Streams.vala',
    'src/Services/Settings.vala',
    'src/Services/Accounts.vala',
    'src/Services/IAccountListener.vala',
    'src/Services/IStreamListener.vala',
    'src/Services/Cache.vala',
    'src/Services/Network.vala',
    'src/API/Account.vala',
    'src/API/Relationship.vala',
    'src/API/Mention.vala',
    'src/API/Tag.vala',
    'src/API/Status.vala',
    'src/API/Visibility.vala',
    'src/API/Notification.vala',
    'src/API/NotificationType.vala',
    'src/API/Attachment.vala',
    'src/Widgets/Avatar.vala',
    'src/Widgets/AccountsButton.vala',
    'src/Widgets/AlignedLabel.vala',
    'src/Widgets/RichLabel.vala',
    'src/Widgets/Status.vala',
    'src/Widgets/Notification.vala',
    'src/Widgets/VisibilityPopover.vala',
    'src/Widgets/Attachment/Box.vala',
    'src/Widgets/Attachment/Item.vala',
    'src/Dialogs/ISavedWindow.vala',
    'src/Dialogs/MainWindow.vala',
    'src/Dialogs/Compose.vala',
    'src/Dialogs/Preferences.vala',
    'src/Views/Base.vala',
    'src/Views/NewAccount.vala',
    'src/Views/Timeline.vala',
    'src/Views/Home.vala',
    'src/Views/Local.vala',
    'src/Views/Federated.vala',
    'src/Views/Notifications.vala',
    'src/Views/Direct.vala',
    'src/Views/ExpandedStatus.vala',
    'src/Views/Profile.vala',
    'src/Views/Favorites.vala',
    'src/Views/Search.vala',
    'src/Views/Hashtag.vala',
    dependencies: [
        dependency('gtk+-3.0', version: '>=3.22.0'),
        dependency('glib-2.0', version: '>=2.30.0'),
        dependency('gee-0.8', version: '>=0.8.5'),
        dependency('granite', version: '>=5.2.0'),
        dependency('json-glib-1.0'),
        dependency('libsoup-2.4'),
        
        meson.get_compiler('vala').find_library('linux', required: true), #Required by Stacktrace.vala
    ],
    install: true,
    link_args: '-export-dynamic'
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
