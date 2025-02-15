sources += files(
    'AnnualReport.vala',
    'FilterEdit.vala',
    'ListEdit.vala',
    'MainWindow.vala',
    'NewAccount.vala',
    'NotificationSettings.vala',
    'Preferences.vala',
    'ProfileEdit.vala',
    'Report.vala',
    'Saveable.vala',
)

if devmode
  sources += files ('DevConsole.vala')
endif

if not without_admin_dashboard
  sources += files ('Admin.vala')
  subdir('Admin')
endif

subdir('Composer')
