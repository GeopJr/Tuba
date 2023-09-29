struct TestUrl {
    public string original;
    public string result;
}

const TestUrl[] URLS = {
    { "web+ap://www.gnome.org/", "https://www.gnome.org/" },
    { "web+ap://www.gnome.org/test", "https://www.gnome.org/test" },
    { "web+ap://www.gnome.org/test?foo=bar", "https://www.gnome.org/test?foo=bar" },
    { "web+ap://www.gnome.org/test?foo=bar&fizz=buzz", "https://www.gnome.org/test?foo=bar&fizz=buzz" },
    { "web+ap://www.gnome.org/test?foo=bar&fizz=buzz#main", "https://www.gnome.org/test?foo=bar&fizz=buzz#main" }
};

public void test_web_ap_handler () {
    foreach (var test_url in URLS) {
        try {
            var uri = Uri.parse (test_url.original, UriFlags.NONE);

            assert_cmpstr (Tuba.WebApHandler.from_uri (uri), CompareOperator.EQ, test_url.result);
        } catch (Error e) {
            critical (e.message);
        }
    }
}

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/test_web_ap_handler", test_web_ap_handler);
    return Test.run ();
}
