struct TestContent {
    public string original;
    public string sanitized;
}

const TestContent[] PANGO_TESTS = {
    { "\n\n<strong>te<em>st</em></strong>\n\n", "\n\n<b>te<i>st</i></b>\n\n" },
    { "\n<br/>\n<strong>te<em>st</em></strong>\n\n", "<br/><b>te<i>st</i></b>" },
};

const TestContent[] RESTORE_TESTS = {
    { "&amp;lt;", "&lt;" },
    { "&lt;&gt;&apos;&foo;&quot;&#39;", "<>'&foo;\"'" }
};

const TestContent[] SIMPLIFY_TESTS = {
    {
        "<a class=\"proletariat\" href=\"https://tuba.geopjr.dev/\" target=\"_blank\">Tuba</a>\n",
        "<a href='https://tuba.geopjr.dev/'>Tuba</a>"
    },
    {
        "<p>Everything is going to be<br />okay</p><div>🐱</div>",
        "Everything is going to be\nokay\n\n🐱"
    }
};

const TestContent[] REMOVE_TAGS_TESTS = {
    {
        "<a class=\"proletariat\" href\"https://tuba.geopjr.dev/\" target=\"_blank\">Tuba</a>\n",
        "Tuba\n"
    },
    {
        "<p>Everything is going to be<br />okay</p><footer>🐱</footer>",
        "Everything is going to be\nokay\n🐱"
    },
    {
        "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>Document</title></head><body><header>I am an<strong><br>example</strong></header><main>another <p>multi <strong>nested <button>one</button></strong></p></main>end</body></html>",
        "DocumentI am an\nexampleanother multi nested one\nend"
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

public void test_remove_tags () {
    foreach (var test_remove_tag in REMOVE_TAGS_TESTS) {
        var res = Tuba.HtmlUtils.remove_tags (test_remove_tag.original);

        assert_cmpstr (res, CompareOperator.EQ, test_remove_tag.sanitized);
    }
}

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/test_pango", test_pango);
    Test.add_func ("/test_restore", test_restore);
    Test.add_func ("/test_simplify", test_simplify);
    Test.add_func ("/test_remove_tags", test_remove_tags);
    return Test.run ();
}
