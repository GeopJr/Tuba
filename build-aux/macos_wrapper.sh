#!/bin/sh

bundle_contents="$( cd "$( dirname "$0" )/../.." >/dev/null 2>&1 && pwd )/Contents"

export XDG_DATA_DIRS="$bundle_contents/Resources/share:$(brew --prefix)/share"

exec "$bundle_contents/MacOS/dev.geopjr.Tuba" "$@"
