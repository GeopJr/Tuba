using GLib;

struct TestContent {
    public string original;
    public string sanitized;
}

const TestContent[] PANGO_TESTS = {
    { "\n\n<strong>te<em>st</em></strong>\n\n", "<b>te<i>st</i></b>" }
};

const TestContent[] RESTORE_TESTS = {
    { "&amp;lt;", "&lt;" },
    { "&lt;&gt;&apos;&foo;&quot;&#39;", "<>'&foo;\"'" }
};

const TestContent[] SIMPLIFY_TESTS = {
    {
        "<a class=\"proletariat\" href\"https://tuba.geopjr.dev/\" target=\"_blank\">Tuba</a>\n",
        "<a  href\"https://tuba.geopjr.dev/\" >Tuba</a>"
    },
    {
        "<p>Everything is going to be<br />okay</p><footer>🐱</footer>",
        "Everything is going to be\nokay\n\n<footer>🐱</footer>"
    }
};

public void test_pango () {
    foreach (var test_pango in PANGO_TESTS) {
        var res = Tuba.HtmlUtils.replace_with_pango_markup (test_pango.original);

        assert_cmpstr (res, CompareOperator.EQ, test_pango.sanitized);
    }
}

public void test_restore () {
    foreach (var test_restore in RESTORE_TESTS) {
        var res = Tuba.HtmlUtils.restore_entities (test_restore.original);

        assert_cmpstr (res, CompareOperator.EQ, test_restore.sanitized);
    }
}

public void test_simplify () {
    foreach (var test_simplify in SIMPLIFY_TESTS) {
        var res = Tuba.HtmlUtils.simplify (test_simplify.original);

        assert_cmpstr (res, CompareOperator.EQ, test_simplify.sanitized);
    }
}

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/test_pango", test_pango);
    Test.add_func ("/test_restore", test_restore);
    Test.add_func ("/test_simplify", test_simplify);
    return Test.run ();
}
