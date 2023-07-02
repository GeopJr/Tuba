public class Tuba.HtmlUtils {

	public const string FALLBACK_TEXT = "[ There was an error parsing this text ]";

	private static Regex? _all_tags_regex;
	public static Regex? all_tags_regex {
		get {
			if (_all_tags_regex == null) {
				try {
					_all_tags_regex = new Regex ("<(.|\n)*?>", GLib.RegexCompileFlags.OPTIMIZE | RegexCompileFlags.CASELESS);
				} catch (GLib.RegexError e) {
					warning (e.message);
				}
			}
			return _all_tags_regex;
		}
	}

	private static Regex? _html_params_regex;
	public static Regex? html_params_regex {
		get {
			if (_html_params_regex == null) {
				try {
					_html_params_regex = new Regex (
						"(class|target|rel|data-user|data-tag|translate)=\"(.|\n)*?\"",
						GLib.RegexCompileFlags.OPTIMIZE | RegexCompileFlags.CASELESS
					);
				} catch (GLib.RegexError e) {
					warning (e.message);
				}
			}
			return _html_params_regex;
		}
	}

	public static string remove_tags (string content) {
		try {
			//TODO: remove this when simplify() uses the HTML parsing class
			var fixed_paragraphs = simplify (content);

			return restore_entities (all_tags_regex?.replace (fixed_paragraphs, -1, 0, "") ?? fixed_paragraphs);
		} catch (Error e) {
			warning (e.message);
			return FALLBACK_TEXT;
		}
	}

	//TODO: Perhaps this should use the HTML parser class
	//      since we depend on it anyway
	public static string simplify (string str) {
		try {
			var divided = str
				.replace ("<br>", "\n")
				.replace ("</br>", "")
				.replace ("<br/>", "\n")
				.replace ("<br />", "\n")
				.replace ("<p>", "")
				.replace ("</p>", "\n\n")
				.replace ("<pre>", "")
				.replace ("</pre>", "");

			var simplified = html_params_regex?.replace (divided, -1, 0, "") ?? divided;

			while (simplified.has_suffix ("\n"))
				simplified = simplified.slice (0, simplified.last_index_of ("\n"));

			return simplified;
		} catch (Error e) {
			warning (@"Can't simplify string \"$str\":\n$(e.message)");
			return str;
		}
	}

	public static string replace_with_pango_markup (string str) {
		return str
			.replace ("\n", "")
			.replace ("<strong>", "<b>")
			.replace ("</strong>", "</b>")
			.replace ("<em>", "<i>")
			.replace ("</em>", "</i>")
			//  .replace("<code>", "<span font_family=\"monospace\">")
			//  .replace("</code>", "</span>\n")
			.replace ("<del>", "<s>")
			.replace ("</del>", "</s>");
	}

	public static string uri_encode (string str) {
		var restored = restore_entities (str);
		return Uri.escape_string (restored);
	}

	public static string restore_entities (string content) {
		return content
			.replace ("&lt;", "<")
			.replace ("&gt;", ">")
			.replace ("&apos;", "'")
			.replace ("&quot;", "\"")
			.replace ("&#39;", "'")

			// Always last since its prone to errors
			// like &amp;lt; => &lt; => <
			.replace ("&amp;", "&");
	}

	public static string escape_entities (string content) {
		return content
			.replace ("&nbsp;", " ")
			.replace ("'", "&apos;");
	}
}
