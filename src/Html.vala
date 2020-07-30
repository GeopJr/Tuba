public class Tootle.Html {

	public const string FALLBACK_TEXT = _("[ There was an error parsing this text :c ]");

	public static string remove_tags (string content) {
		try {
			var fixed_paragraphs = simplify (content);
			var all_tags = new Regex ("<(.|\n)*?>", RegexCompileFlags.CASELESS);
			return Widgets.RichLabel.restore_entities (all_tags.replace (fixed_paragraphs, -1, 0, ""));
		}
		catch (Error e) {
			warning (e.message);
			return FALLBACK_TEXT;
		}
	}

	public static string simplify (string str) {
		try {
			var divided = str
			.replace("<br>", "\n")
			.replace("</br>", "")
			.replace("<br />", "\n")
			.replace("<p>", "")
			.replace("</p>", "\n\n");

			var html_params = new Regex ("(class|target|rel)=\"(.|\n)*?\"", RegexCompileFlags.CASELESS);
			var simplified = html_params.replace (divided, -1, 0, "");

			while (simplified.has_suffix ("\n"))
				simplified = simplified.slice (0, simplified.last_index_of ("\n"));

			return simplified;
		}
		catch (Error e) {
			warning (e.message);
			return FALLBACK_TEXT;
		}
	}

	public static string uri_encode (string str) {
		var restored = Widgets.RichLabel.restore_entities (str);
		return Soup.URI.encode (restored, ";&+");
	}

}
