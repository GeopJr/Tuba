project('com.github.bleakgrey.tootle', 'vala', 'c')

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
        '-DHANDY_USE_UNSTABLE_API',
    ],
    language: 'c',
)

# This is needed to make libhandy 1.0 work with vala.
# Without this, vala will complain:
# "X is not available in libhandy-1 0.81.0. Use libhandy-1 >= 1.0"
# FIXME Disable --disable-since-check after libhandy 1.0 is released
add_project_arguments (
  '--disable-since-check',
  language: 'vala'
)


asresources = gnome.compile_resources(
  'as-resources', 'data/gresource.xml',
  source_dir: 'data',
  c_name: 'as'
)

libhandy_dep = dependency('libhandy-1', version: '>= 0.80.0', required: false)
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
    'src/Build.vala',
    'src/Application.vala',
    'src/Desktop.vala',
    'src/Drawing.vala',
    'src/Html.vala',
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
    'src/API/Entity.vala',
    'src/Widgets/Widgetizable.vala',
    'src/Widgets/Avatar.vala',
    'src/Widgets/AccountsButton.vala',
    'src/Widgets/TimelineFilter.vala',
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
    'src/Views/Conversations.vala',
    'src/Views/Bookmarks.vala',
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
        dependency('libsoup-2.4'),
        dependency('json-glib-1.0', version: '>=1.4.4'),
        libhandy_dep,
    ],
    install: true,
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
