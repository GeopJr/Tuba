struct TestCelebrate {
    public DateTime date;
    public string[] css_classes;
}

private TestCelebrate[] get_celebrate_tests () {
    return {
        TestCelebrate () { date = new GLib.DateTime.local (2022, 5, 19, 0, 0, 0), css_classes = { "theme-agender" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 5, 18, 23, 59, 0), css_classes = { } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 5, 20, 0, 0, 0), css_classes = { } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 10, 26, 0, 0, 0), css_classes = { "theme-intersex" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 10, 25, 23, 59, 0), css_classes = { "theme-ace" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 10, 27, 0, 0, 0), css_classes = { "theme-ace" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 11, 8, 0, 0, 0), css_classes = { "theme-intersex" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 11, 7, 23, 59, 0), css_classes = { } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 11, 9, 0, 0, 0), css_classes = { } },

        TestCelebrate () { date = new GLib.DateTime.local (2022, 10, 8, 0, 0, 0), css_classes = { "theme-lesbian" } },
        TestCelebrate () {
            date = new GLib.DateTime.local (2022, 10, 7, 23, 59, 0),
            css_classes = { "theme-black-history" }
        },
        TestCelebrate () {
            date = new GLib.DateTime.local (2022, 10, 9, 0, 0, 0),
            css_classes = { "theme-black-history" }
        },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 4, 26, 0, 0, 0), css_classes = { "theme-lesbian" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 5, 2, 0, 0, 0), css_classes = { "theme-lesbian" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 4, 25, 23, 59, 0), css_classes = { } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 5, 3, 0, 0, 0), css_classes = { } },

        TestCelebrate () { date = new GLib.DateTime.local (2022, 12, 1, 0, 0, 0), css_classes = { "theme-aids" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 11, 30, 23, 59, 0), css_classes = { } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 12, 2, 0, 0, 0), css_classes = { } },

        TestCelebrate () { date = new GLib.DateTime.local (2022, 6, 18, 0, 0, 0), css_classes = { "theme-autism" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 6, 17, 23, 59, 0), css_classes = { } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 6, 19, 0, 0, 0), css_classes = { } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 5, 24, 0, 0, 0), css_classes = { "theme-pan" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 5, 23, 23, 59, 0), css_classes = { } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 5, 25, 0, 0, 0), css_classes = { } },

        TestCelebrate () { date = new GLib.DateTime.local (2022, 11, 13, 0, 0, 0), css_classes = { "theme-trans" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 11, 19, 0, 0, 0), css_classes = { "theme-trans" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 11, 20, 0, 0, 0), css_classes = { "theme-trans" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 3, 31, 0, 0, 0), css_classes = { "theme-trans" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 11, 12, 23, 59, 0), css_classes = { } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 11, 21, 0, 0, 0), css_classes = { } },
        TestCelebrate () { date = new GLib.DateTime.local (2023, 2, 19, 0, 0, 0), css_classes = { "theme-aro" } },
        TestCelebrate () { date = new GLib.DateTime.local (2023, 2, 25, 0, 0, 0), css_classes = { "theme-aro" } },
        TestCelebrate () {
            date = new GLib.DateTime.local (2023, 2, 18, 23, 59, 0),
            css_classes = { "theme-black-history" }
        },
        TestCelebrate () {
            date = new GLib.DateTime.local (2023, 2, 26, 0, 0, 0),
            css_classes = { "theme-black-history" }
        },

        TestCelebrate () {
            date = new GLib.DateTime.local (2022, 10, 23, 0, 0, 0),
            css_classes = { "theme-ace" }
        },
        TestCelebrate () {
            date = new GLib.DateTime.local (2022, 10, 29, 0, 0, 0),
            css_classes = { "theme-ace" }
        },
        TestCelebrate () {
            date = new GLib.DateTime.local (2022, 10, 22, 23, 59, 0),
            css_classes = { "theme-black-history" }
        },
        TestCelebrate () {
            date = new GLib.DateTime.local (2022, 10, 30, 0, 0, 0),
            css_classes = { "theme-black-history" }
        }
        ,
        TestCelebrate () { date = new GLib.DateTime.local (2022, 9, 16, 0, 0, 0), css_classes = { "theme-bi" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 9, 23, 0, 0, 0), css_classes = { "theme-bi" } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 9, 15, 23, 59, 0), css_classes = { } },
        TestCelebrate () { date = new GLib.DateTime.local (2022, 9, 24, 0, 0, 0), css_classes = { } },

        TestCelebrate () {
            date = new GLib.DateTime.local (2023, 7, 10, 0, 0, 0),
            css_classes = { "theme-non-binary" }
        },
        TestCelebrate () {
            date = new GLib.DateTime.local (2023, 7, 16, 0, 0, 0),
            css_classes = { "theme-non-binary" }
        },
        TestCelebrate () {
            date = new GLib.DateTime.local (2023, 7, 8, 23, 59, 0),
            css_classes = { "theme-disability" }
        },
        TestCelebrate () {
            date = new GLib.DateTime.local (2023, 7, 17, 0, 0, 0),
            css_classes = { "theme-disability" }
        },

        TestCelebrate () {
            date = new GLib.DateTime.local (2023, 7, 1, 0, 0, 0),
            css_classes = { "theme-disability" }
        },
        TestCelebrate () {
            date = new GLib.DateTime.local (2023, 7, 31, 0, 0, 0),
            css_classes = { "theme-disability" }
        },
        TestCelebrate () { date = new GLib.DateTime.local (2023, 6, 30, 23, 59, 0), css_classes = { } },
        TestCelebrate () { date = new GLib.DateTime.local (2023, 8, 1, 0, 0, 0), css_classes = { } },
        TestCelebrate () {
            date = new GLib.DateTime.local (2023, 2, 1, 0, 0, 0),
            css_classes = { "theme-black-history" }
        },
        TestCelebrate () {
            date = new GLib.DateTime.local (2023, 2, 28, 0, 0, 0),
            css_classes = { "theme-black-history" }
        },
        TestCelebrate () { date = new GLib.DateTime.local (2023, 1, 31, 23, 59, 0), css_classes = { } },
        TestCelebrate () { date = new GLib.DateTime.local (2023, 3, 1, 0, 0, 0), css_classes = { } },
        TestCelebrate () {
            date = new GLib.DateTime.local (2023, 10, 1, 0, 0, 0),
            css_classes = { "theme-black-history" }
        },
        TestCelebrate () {
            date = new GLib.DateTime.local (2023, 10, 31, 0, 0, 0),
            css_classes = { "theme-black-history", "theme-halloween" }
        },
        TestCelebrate () { date = new GLib.DateTime.local (2023, 9, 30, 23, 59, 0), css_classes = { } },
        TestCelebrate () { date = new GLib.DateTime.local (2023, 11, 1, 0, 0, 0), css_classes = { } },
    };
}


public void test_celebrate () {
    var tests = get_celebrate_tests ();
    foreach (var test_celebrate in tests) {
        var res = Tuba.Celebrate.get_celebration_css_class (test_celebrate.date);


        if (res == "") {
            assert_cmpint (test_celebrate.css_classes.length, CompareOperator.EQ, 0);
        } else {
            var in_classes = res in test_celebrate.css_classes;
            if (!in_classes)
                critical (@"Missing ($(test_celebrate.date)): $res");
            assert_true (res in test_celebrate.css_classes);
        }
    }
}

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/test_celebrate", test_celebrate);
    return Test.run ();
}
