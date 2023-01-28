project(
    'dev.geopjr.tooth',
    ['c', 'vala'],
    version: '2.1.0',
    meson_version: '>= 0.56.0',
    default_options: [
        'warning_level=2',
        'werror=false',
    ],
)

add_global_arguments(
    [
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    ],
    language: 'c',
)

devel = get_option('devel')
config = configuration_data()
config.set('EXEC_NAME', meson.project_name())
config.set('GETTEXT_PACKAGE', meson.project_name())
config.set('RESOURCES', '/' + '/'.join(meson.project_name().split('.')) + '/')
config.set('VERSION', meson.project_version())
config.set('PREFIX', get_option('prefix'))
config.set('PROFILE', devel ? 'development' : 'production')
config.set('NAME', 'Tooth')
config.set('WEBSITE', 'https://github.com/GeopJr/tooth')
config.set('SUPPORT_WEBSITE', 'https://github.com/GeopJr/tooth/issues')
config.set(
    'COPYRIGHT',
    '© 2022 bleak_grey\n© 2022 Evangelos \"GeopJr\" Paterakis',
)

if devel
  git = find_program('git')
  if git.found()
    branch = run_command('git', 'branch', '--show-current', check: true).stdout().strip()
    revision = run_command('git', 'rev-parse', '--short', 'HEAD', check: true).stdout().strip()
    version = '@0@-@1@'.format(branch, revision)
    config.set('VERSION', version)
  endif
endif

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

sources = files(
    'src/API/Account.vala',
    'src/API/AccountField.vala',
    'src/API/Attachment.vala',
    'src/API/Conversation.vala',
    'src/API/Emoji.vala',
    'src/API/EmojiReaction.vala',
    'src/API/Entity.vala',
    'src/API/List.vala',
    'src/API/Mention.vala',
    'src/API/Notification.vala',
    'src/API/Pleroma.vala',
    'src/API/Relationship.vala',
    'src/API/SearchResults.vala',
    'src/API/Status.vala',
    'src/API/Tag.vala',
    'src/API/Poll.vala',
    'src/API/PollOption.vala',
    'src/Application.vala',
    'src/Dialogs/Composer/AttachmentsPage.vala',
    'src/Dialogs/Composer/AttachmentsPageAttachment.vala',
    'src/Dialogs/Composer/Dialog.vala',
    'src/Dialogs/Composer/EditorPage.vala',
    'src/Dialogs/Composer/Page.vala',
    'src/Dialogs/Composer/PollPage.vala',
    'src/Dialogs/MainWindow.vala',
    'src/Dialogs/NewAccount.vala',
    'src/Dialogs/Preferences.vala',
    'src/Dialogs/Saveable.vala',
    'src/Services/Accounts/AccountHolder.vala',
    'src/Services/Accounts/AccountStore.vala',
    'src/Services/Accounts/InstanceAccount.vala',
    'src/Services/Accounts/Mastodon/Account.vala',
    'src/Services/Accounts/Places.vala',
    'src/Services/Accounts/SecretAccountStore.vala',
    'src/Services/Cache/AbstractCache.vala',
    'src/Services/Cache/EntityCache.vala',
    'src/Services/Cache/ImageCache.vala',
    'src/Services/Network/Network.vala',
    'src/Services/Network/Request.vala',
    'src/Services/Network/Streamable.vala',
    'src/Services/Network/Streams.vala',
    'src/Services/Settings.vala',
    'src/Utils/DateTime.vala',
    'src/Utils/Host.vala',
    'src/Utils/Html.vala',
    'src/Views/Base.vala',
    'src/Views/Bookmarks.vala',
    'src/Views/ContentBase.vala',
    'src/Views/Conversations.vala',
    'src/Views/Favorites.vala',
    'src/Views/Federated.vala',
    'src/Views/Hashtag.vala',
    'src/Views/Home.vala',
    'src/Views/List.vala',
    'src/Views/Lists.vala',
    'src/Views/Local.vala',
    'src/Views/FollowRequests.vala',
    'src/Views/Main.vala',
    'src/Views/Notifications.vala',
    'src/Views/Profile.vala',
    'src/Views/Search.vala',
    'src/Views/Sidebar.vala',
    'src/Views/TabbedBase.vala',
    'src/Views/Thread.vala',
    'src/Views/Timeline.vala',
    'src/Widgets/Attachment/Box.vala',
    'src/Widgets/Attachment/Image.vala',
    'src/Widgets/Attachment/Item.vala',
    'src/Widgets/Avatar.vala',
    'src/Widgets/Background.vala',
    'src/Widgets/Conversation.vala',
    'src/Widgets/Emoji.vala',
    'src/Widgets/LockableToggleButton.vala',
    'src/Widgets/MarkupView.vala',
    'src/Widgets/Notification.vala',
    'src/Widgets/RelationshipButton.vala',
    'src/Widgets/RichLabel.vala',
    'src/Widgets/RichLabelContainer.vala',
    'src/Widgets/EmojiLabel.vala',
    'src/Widgets/Status.vala',
    'src/Widgets/StatusActionButton.vala',
    'src/Widgets/Widgetizable.vala',
    'src/Widgets/VoteBox.vala',
    'src/Widgets/VoteCheckButton.vala',
)

build_file = configure_file(
    input: 'src/Build.vala.in',
    output: 'Build.vala',
    configuration: config,
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

# gnome.post_install() is available since meson 0.59.0
# Distributions use their own tooling (e.g. postinst, triggers, etc)
# so it is okay if the post_install() is not run on distro builds
if meson.version().version_compare('>=0.59.0')
  gnome.post_install(
    glib_compile_schemas: true,
    gtk_update_icon_cache: true,
    update_desktop_database: true,
  )
else
  meson.add_install_script('build-aux/meson_post_install.py')
endif
