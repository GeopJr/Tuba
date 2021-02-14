public class Tootle.HtmlUtils {

	public const string FALLBACK_TEXT = _("[ There was an error parsing this text :c ]");

	public static string remove_tags (string content) {
		try {
			//TODO: remove this when simplify() uses the HTML parsing class
			var fixed_paragraphs = simplify (content);

			var all_tags = new Regex ("<(.|\n)*?>", RegexCompileFlags.CASELESS);
			return Widgets.RichLabel.restore_entities (all_tags.replace (fixed_paragraphs, -1, 0, ""));
		}
		catch (Error e) {
			warning (e.message);
			return FALLBACK_TEXT;
		}
	}

	//TODO: Perhaps this should use the HTML parser class
	//      since we depend on it anyway
	public static string simplify (string str) {
		try {
			var divided = str
			.replace("<br>", "\n")
			.replace("</br>", "")
			.replace("<br/>", "\n")
			.replace("<br />", "\n")
			.replace("<p>", "")
			.replace("</p>", "\n\n")
			.replace("<pre>", "")
			.replace("</pre>", "");

			var html_params = new Regex ("(class|target|rel|data-user|data-tag)=\"(.|\n)*?\"", RegexCompileFlags.CASELESS);
			var simplified = html_params.replace (divided, -1, 0, "");

			while (simplified.has_suffix ("\n"))
				simplified = simplified.slice (0, simplified.last_index_of ("\n"));

			return simplified;
		}
		catch (Error e) {
			warning (@"Can't simplify string \"$str\":\n$(e.message)");
			return remove_tags (str);
		}
	}

	public static string replace_with_pango_markup (string str) {
		return str
			.replace("<strong>", "<b>")
			.replace("</strong>", "</b>")
			.replace("<em>", "<i>")
			.replace("</em>", "</i>")
			.replace("<code>", "<span font_family=\"monospace\">")
			.replace("</code>", "</span>\n")
			.replace("<del>", "<s>")
			.replace("</del>", "</s>");
	}

	public static string uri_encode (string str) {
		var restored = Widgets.RichLabel.restore_entities (str);
		return Soup.URI.encode (restored, ";&+");
	}

}
