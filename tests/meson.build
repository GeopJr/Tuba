unit_tests = {
    'Blurhash': files (
        meson.project_source_root() + '/src/Utils/Blurhash.vala'
    ),
    'Celebrate': files (
        meson.project_source_root() + '/src/Utils/Celebrate.vala'
    ),
    'Counting': files (
        meson.project_source_root() + '/src/Utils/Counting.vala'
    ),
    'DateTime': files (
        meson.project_source_root() + '/src/Utils/DateTime.vala'
    ),
    'Html': files (
        meson.project_source_root() + '/src/Utils/Html.vala',
    ),
    'ShareHandler': files (
        meson.project_source_root() + '/src/Utils/ShareHandler.vala'
    ),
    'Tracking': files (
        meson.project_source_root() + '/src/Utils/Tracking.vala'
    ),
    'Units': files (
        meson.project_source_root() + '/src/Utils/Units.vala'
    ),
    'WebApHandler': files (
        meson.project_source_root() + '/src/Utils/WebApHandler.vala'
    )
}

foreach name, t_sources : unit_tests
    test(name, executable(name, name + '.test.vala', sources: t_sources, dependencies: final_deps))
endforeach
