public class Tuba.Counting {
	static GLib.Regex mention_regex;
	static construct {
		try {
			mention_regex = new GLib.Regex ("(^|[^/\\w])@(([a-z0-9_]+)@[a-z0-9.-]+[a-z0-9]+)", GLib.RegexCompileFlags.OPTIMIZE | GLib.RegexCompileFlags.CASELESS);
		} catch (GLib.RegexError e) {
			critical (e.message);
		}
	}

	public static int chars (string content, string language = "en") {
		int res = 0;
		var icu_err = Icu.ErrorCode.ZERO_ERROR;
		var icu_text = Icu.Text.open_utf8 (null, content.data, ref icu_err);
		var word_breaker = Icu.BreakIterator.open (
			CHARACTER, language, null, -1, ref icu_err
		);
		word_breaker.set_utext (icu_text, ref icu_err);

		if (icu_err.is_success ()) {
			while (word_breaker.next () != Icu.BreakIterator.DONE) {
				res += 1;
			}
		} else {
			// If the language is not "en" and it fails,
			// try again on "en".
			if (language != "en") return chars (content);
			res += content.length;
		}

		return res;
	}

	public static string replace_mentions (string content) {
		new Counting ();

		try {
			return mention_regex.replace (content, content.length, 0, "\\1@\\3");
		} catch (GLib.RegexError e) {
			warning (e.message);
			return content;
		}
	}
}
