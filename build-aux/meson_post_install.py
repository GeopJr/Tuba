#!/usr/bin/env python3

import os
import subprocess

prefix     = os.environ.get('MESON_INSTALL_PREFIX', '/usr/local')
data_dir   = os.path.join(prefix, 'share')
icon_dir   = os.path.join(data_dir, 'icons', 'hicolor')
app_dir    = os.path.join(data_dir, 'applications')
schema_dir = os.path.join(data_dir, 'glib-2.0', 'schemas')

if not os.environ.get('DESTDIR'):
    print('Compiling gsettings schemas...')
    subprocess.call (['glib-compile-schemas', schema_dir])

    print('Update icon cache...')
    subprocess.call(['gtk-update-icon-cache', '-f', '-t', icon_dir])

    print('Updating desktop database...')
    subprocess.call(['update-desktop-database', '-q', app_dir])
