struct TestExtract {
	public string source;
	public Tuba.TagExtractor.Result? extracted;
}

TestExtract[] get_extractions () {
	return {
		{
			"I am a <a href='https://gnome.org/'>pango</a> markup label\n\n<a href='https://gnome.org/tags/opensource'>#opensource</a> <a href='https://gnome.org/tags/cookies'>#cookies</a> <a href='https://gnome.org/tags/frogs'>#frogs</a> <a href='https://gnome.org/tags/sunny'>#sunny</a>",
			{
				"I am a <a href='https://gnome.org/'>pango</a> markup label", {
					{"opensource", "https://gnome.org/tags/opensource"},
					{"cookies", "https://gnome.org/tags/cookies"},
					{"frogs", "https://gnome.org/tags/frogs"},
					{"sunny", "https://gnome.org/tags/sunny"}
				}
			}
		},
		{
			"Same as before but no spaces between tags\n\n<a href='https://gnome.org/tags/opensource'>#opensource</a><a href='https://gnome.org/tags/cookies'>#cookies</a><a href='https://gnome.org/tags/frogs'>#frogs</a><a href='https://gnome.org/tags/sunny'>#sunny</a>",
			{
				"Same as before but no spaces between tags", {
					{"opensource", "https://gnome.org/tags/opensource"},
					{"cookies", "https://gnome.org/tags/cookies"},
					{"frogs", "https://gnome.org/tags/frogs"},
					{"sunny", "https://gnome.org/tags/sunny"}
				}
			}
		},
		{
			"Same as before but there's a newline in the middle\n\n<a href='https://gnome.org/tags/opensource'>#opensource</a><a href='https://gnome.org/tags/cookies'>#cookies</a>\n<a href='https://gnome.org/tags/frogs'>#frogs</a><a href='https://gnome.org/tags/sunny'>#sunny</a>",
			null
		},
		{
			"Same as before but there's non-hashtag text in the middle\n\n<a href='https://gnome.org/tags/opensource'>#opensource</a><a href='https://gnome.org/tags/cookies'>#cookies</a> hello? <a href='https://gnome.org/tags/frogs'>#frogs</a><a href='https://gnome.org/tags/sunny'>#sunny</a>",
			null
		},
		{
			"Same as before but there's a hashtag without #\n\n<a href='https://gnome.org/tags/opensource'>#opensource</a><a href='https://gnome.org/tags/cookies'>#cookies</a> hello? <a href='https://gnome.org/tags/frogs'>frogs</a><a href='https://gnome.org/tags/sunny'>#sunny</a>",
			null
		},
		{
			"Same as before but single newline\n<a href='https://gnome.org/tags/opensource'>#opensource</a><a href='https://gnome.org/tags/cookies'>#cookies</a><a href='https://gnome.org/tags/frogs'>#frogs</a><a href='https://gnome.org/tags/sunny'>#sunny</a>",
			null
		},
		{
			"Same as before but no tags\n\n",
			{
				"Same as before but no tags", null
			}
		},
	};
}

public void test_extractor () {
	foreach (var test_extract in get_extractions ()) {
		var extraction = Tuba.TagExtractor.from_string (test_extract.source);
		if (test_extract.extracted == null) {
			assert_true (extraction.input_without_tags == null);
			assert_true (extraction.extracted_tags == null);
		} else {
			assert_cmpstr (test_extract.extracted.input_without_tags, CompareOperator.EQ, extraction.input_without_tags);
			if (test_extract.extracted.extracted_tags == null) {
				assert_true (extraction.extracted_tags == null);
			} else {
				assert_cmpint (test_extract.extracted.extracted_tags.length, CompareOperator.EQ, extraction.extracted_tags.length);

				for (int i = 0; i < test_extract.extracted.extracted_tags.length; i++) {
					assert_cmpstr (test_extract.extracted.extracted_tags[i].tag, CompareOperator.EQ, extraction.extracted_tags[i].tag);
					assert_cmpstr (test_extract.extracted.extracted_tags[i].link, CompareOperator.EQ, extraction.extracted_tags[i].link);
				}
			}
		}
	}
}

public int main (string[] args) {
	Test.init (ref args);

	Test.add_func ("/test_extractor", test_extractor);
	return Test.run ();
}
