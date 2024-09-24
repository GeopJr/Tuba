struct TestShare {
	public string original;
	public Tuba.ShareHandler.ShareResult? result;
}

TestShare[] get_shares () {
	return {
		{ "tuba://share", null },
		{ "tuba://share?text=foo%20bar", Tuba.ShareHandler.ShareResult () { text = "foo bar", cw = null } },
		{ "tuba://share?text=foo%20BAR&cw=bar%20foo", Tuba.ShareHandler.ShareResult () { text = "foo BAR", cw = "bar foo" } },
		{ "tuba://share?text=foo%20bar&cw=%26foo%3Dbar", Tuba.ShareHandler.ShareResult () { text = "foo bar", cw = "&foo=bar" } },
		{ "tuba://share?cw=%26foo%3Dbar", null },
		{ "tuba://share?text=&cw=", Tuba.ShareHandler.ShareResult () { text = "", cw = "" } }
	};
}

public void test_share_handler () {
	foreach (var test_share in get_shares ()) {
		try {
			var uri = Uri.parse (test_share.original, UriFlags.ENCODED);
			var result = Tuba.ShareHandler.from_uri (uri);

			if (result == null) {
				assert_true (test_share.result == null);
			} else {
				assert_cmpstr (result.text, CompareOperator.EQ, test_share.result.text);
				if (result.cw == null) {
					assert_true (test_share.result.cw == null);
				} else {
					assert_cmpstr (result.cw, CompareOperator.EQ, test_share.result.cw);
				}
			}
		} catch (Error e) {
			critical (e.message);
		}
	}
}

public int main (string[] args) {
	Test.init (ref args);

	Test.add_func ("/test_share_handler", test_share_handler);
	return Test.run ();
}
