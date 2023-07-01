using GLib;

struct TestUrl {
    public string original;
    public string result;
}

const TestUrl[] URLS = {
    { "https://www.gnome.org/", "https://www.gnome.org/" },
    { "https://www.gnome.org/test", "https://www.gnome.org/test" },
    { "https://www.gnome.org/test?foo=bar", "https://www.gnome.org/test?foo=bar" },
    { "https://www.gnome.org/test?foo=bar&fizz=buzz", "https://www.gnome.org/test?foo=bar&fizz=buzz" },
    { "https://www.gnome.org/test?foo=bar&fizz=buzz#main", "https://www.gnome.org/test?foo=bar&fizz=buzz#main" },
    { "https://www.gnome.org/test?tag=soft_clothes", "https://www.gnome.org/test?tag=soft_clothes" },
    { "https://www.gnome.org/test?utm_source=tuba", "https://www.gnome.org/test" },
    { "https://www.gnome.org/test?utm_source=tuba#main", "https://www.gnome.org/test#main" },
    { "https://www.gnome.org/test?utm_source=tuba&foo=bar", "https://www.gnome.org/test?foo=bar" },
    { "https://www.gnome.org/test?utm_source=tuba&foo=bar&oft_id=1312#main", "https://www.gnome.org/test?foo=bar#main" }
};

public void test_strip_utm () {
    foreach (var test_url in URLS) {
        var stripped_url = Tuba.Tracking.strip_utm (test_url.original);

        assert_cmpstr (stripped_url, CompareOperator.EQ, test_url.result);
    }
}

public void test_strip_utm_fallback () {
    foreach (var test_url in URLS) {
        if (!("?" in test_url.original)) continue;
        var stripped_url = Tuba.Tracking.strip_utm_fallback (test_url.original);
        assert_cmpstr (stripped_url, CompareOperator.EQ, test_url.result);
    }
}

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/test_strip_utm", test_strip_utm);
    Test.add_func ("/test_strip_utm_fallback", test_strip_utm_fallback);
    return Test.run ();
}
