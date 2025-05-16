struct TestUrl {
	public string original;
	public string result;
}

struct TestUrlCleanup {
	public string content;
	public GLib.Uri[] uris;
	public string stripped_content;
	public int characters_reserved_per_url;
	public string replaced_content;
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

TestUrlCleanup[] get_cleanup_urls () {
	TestUrlCleanup[] res = {};

	res += TestUrlCleanup () {
		content = "https :/ /www .gnome .org/",
		uris = {},
		stripped_content = "https :/ /www .gnome .org/",
		characters_reserved_per_url = 1,
		replaced_content = "https :/ /www .gnome .org/"
	};

	res += TestUrlCleanup () {
		content = "https://www.gnome.org/",
		uris = {GLib.Uri.build (GLib.UriFlags.ENCODED, "https", null, "www.gnome.org/", -1, "", null, null)},
		stripped_content = "https://www.gnome.org/",
		characters_reserved_per_url = 15,
		replaced_content = "XXXXXXXXXXXXXXX"
	};

	res += TestUrlCleanup () {
		content = "Albums:\nDorian Electra - Fanfare https://dorianelectramusic.bandcamp.com/album/fanfare-explicit?foo=bar&fizz=buzz#main\n[bo en - pale machine 2](https://boen.bandcamp.com/album/pale-machine-2?utm_source=tuba&foo=bar&oft_id=1312#main)\n<a href=\"https://osno1.bandcamp.com/album/i-just-dont-wanna-name-it-anything-with-beach-in-the-title?tag=soft_clothes\">laura les - i just dont wanna name it anything with \"beach\" in the title</a>",
		uris = {GLib.Uri.build (GLib.UriFlags.ENCODED, "https", null, "dorianelectramusic.bandcamp.com", -1, "/album/fanfare-explicit", "foo=bar&fizz=buzz", "main"), GLib.Uri.build (GLib.UriFlags.ENCODED, "https", null, "boen.bandcamp.com", -1, "/album/pale-machine-2", "utm_source=tuba&foo=bar&oft_id=1312", "main"), GLib.Uri.build (GLib.UriFlags.ENCODED, "https", null, "osno1.bandcamp.com", -1, "/album/i-just-dont-wanna-name-it-anything-with-beach-in-the-title", "tag=soft_clothes", null)},
		stripped_content = "Albums:\nDorian Electra - Fanfare https://dorianelectramusic.bandcamp.com/album/fanfare-explicit?foo=bar&fizz=buzz#main\n[bo en - pale machine 2](https://boen.bandcamp.com/album/pale-machine-2?foo=bar#main)\n<a href=\"https://osno1.bandcamp.com/album/i-just-dont-wanna-name-it-anything-with-beach-in-the-title?tag=soft_clothes\">laura les - i just dont wanna name it anything with \"beach\" in the title</a>",
		characters_reserved_per_url = 6,
		replaced_content = "Albums:\nDorian Electra - Fanfare XXXXXX\n[bo en - pale machine 2](XXXXXX)\n<a href=\"XXXXXX\">laura les - i just dont wanna name it anything with \"beach\" in the title</a>"
	};

	res += TestUrlCleanup () {
		content = "HTTPS://www.gnome.org/",
		uris = {GLib.Uri.build (GLib.UriFlags.ENCODED, "https", null, "www.gnome.org/", -1, "", null, null)},
		stripped_content = "HTTPS://www.gnome.org/",
		characters_reserved_per_url = -5,
		replaced_content = "HTTPS://www.gnome.org/"
	};

	res += TestUrlCleanup () {
		content = "https://www.gnome.org/test?oft_c=1312 https://www.gnome.org/test?foo=bar&oft_c=1312 https://www.gnome.org/test?oft_c=1312&foo=bar&ad_id=1312",
		uris = {GLib.Uri.build (GLib.UriFlags.ENCODED, "https", null, "www.gnome.org", -1, "/test", "oft_c=1312", null), GLib.Uri.build (GLib.UriFlags.ENCODED, "https", null, "www.gnome.org", -1, "/test", "foo=bar&oft_c=1312", null), GLib.Uri.build (GLib.UriFlags.ENCODED, "https", null, "www.gnome.org", -1, "/test", "oft_c=1312&foo=bar&ad_id=1312", null)},
		stripped_content = "https://www.gnome.org/test https://www.gnome.org/test?foo=bar https://www.gnome.org/test?foo=bar",
		characters_reserved_per_url = 1,
		replaced_content = "X X X"
	};

	res += TestUrlCleanup () {
		content = "dat://www.gnome.org/",
		uris = {},
		stripped_content = "dat://www.gnome.org/",
		characters_reserved_per_url = 23,
		replaced_content = "dat://www.gnome.org/"
	};

	return res;
}

public void test_strip_utm () {
	foreach (var test_url in URLS) {
		var stripped_url = Tuba.Utils.Tracking.strip_utm (test_url.original);

		assert_cmpstr (stripped_url, CompareOperator.EQ, test_url.result);
	}
}

public void test_strip_utm_fallback () {
	foreach (var test_url in URLS) {
		if (!("?" in test_url.original)) continue;
		var stripped_url = Tuba.Utils.Tracking.strip_utm_fallback (test_url.original);
		assert_cmpstr (stripped_url, CompareOperator.EQ, test_url.result);
	}
}

public void test_cleanup () {
	foreach (var test_url in get_cleanup_urls ()) {
		GLib.Uri[] extracted_uris = Tuba.Utils.Tracking.extract_uris (test_url.content);
		assert_cmpint (extracted_uris.length, CompareOperator.EQ, test_url.uris.length);

		for (var i=0; i < test_url.uris.length; i++) {
			assert_cmpstr (extracted_uris[i].to_string (), CompareOperator.EQ, test_url.uris[i].to_string ());
		}

		assert_cmpstr (
			Tuba.Utils.Tracking.cleanup_content_with_uris (
				test_url.content,
				test_url.uris,
				Tuba.Utils.Tracking.CleanupType.STRIP_TRACKING
			),
			CompareOperator.EQ,
			test_url.stripped_content
		);

		assert_cmpstr (
			Tuba.Utils.Tracking.cleanup_content_with_uris (
				test_url.content,
				test_url.uris,
				Tuba.Utils.Tracking.CleanupType.SPECIFIC_LENGTH,
				test_url.characters_reserved_per_url
			),
			CompareOperator.EQ,
			test_url.replaced_content
		);
	}
}

public int main (string[] args) {
	Test.init (ref args);

	Test.add_func ("/test_strip_utm", test_strip_utm);
	Test.add_func ("/test_strip_utm_fallback", test_strip_utm_fallback);
	Test.add_func ("/test_cleanup", test_cleanup);
	return Test.run ();
}
