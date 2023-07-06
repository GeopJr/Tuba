unit_tests = {
    'Celebrate': files (
        meson.project_source_root() + '/src/Utils/Celebrate.vala'
    ),
    'DateTime': files (
        meson.project_source_root() + '/src/Utils/DateTime.vala'
    ),
    'Html': files (
        meson.project_source_root() + '/src/Utils/Html.vala',
    ),
    'Tracking': files (
        meson.project_source_root() + '/src/Utils/Tracking.vala'
    )
}

foreach name, t_sources : unit_tests
    test(name, executable(name, name + '.test.vala', sources: t_sources, dependencies: final_deps))
endforeach
