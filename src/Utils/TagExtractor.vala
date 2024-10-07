public class Tuba.TagExtractor {
	public struct Tag {
		public string tag;
		public string link;
	}

	public struct Result {
		public string? input_without_tags;
		public Tag[]? extracted_tags;
	}

	static GLib.Regex pango_uri_regex;
	static construct {
		try {
			pango_uri_regex = new GLib.Regex ("<a href='(?<href>http[^']+)'>#(?<tag>[^<]+)<\\/a>", GLib.RegexCompileFlags.OPTIMIZE | GLib.RegexCompileFlags.CASELESS);
		} catch (GLib.RegexError e) {
			critical (e.message);
		}
	}

	public static Result from_string (string input) {
		new TagExtractor ();
		Result res = { null, null };

		int last_paragraph_begin = input.last_index_of ("\n\n");
		if (last_paragraph_begin == -1) return res;

		string last_paragraph = input.slice (last_paragraph_begin, input.length);
		if (last_paragraph.strip ().last_index_of_char ('\n') > -1) return res;

		try {
			Tag[]? extracted_tags = null;
			string cleaned_up_paragraph = pango_uri_regex.replace_eval (last_paragraph, last_paragraph.length, 0, 0, (match_info, data) => {
				data.append ("");

				if (extracted_tags == null) extracted_tags = {};
				extracted_tags += Tag () {
					tag = match_info.fetch_named ("tag"),
					link = match_info.fetch_named ("href")
				};

				return false;
			}).strip ();
			if (cleaned_up_paragraph != "") return res;

			res.extracted_tags = extracted_tags;
			res.input_without_tags = input.slice (0, last_paragraph_begin);
		} catch (GLib.RegexError e) {
			critical (e.message);
		}

		return res;
	}
}
