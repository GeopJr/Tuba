public class Tuba.HtmlUtils {
	public static string remove_tags (string content) {
		var fixed_paragraphs = content;

		string to_parse = HtmlUtils.replace_with_pango_markup (content);
		if (to_parse != "") {
			var doc = Html.Doc.read_doc (to_parse, "", "utf8");
			if (doc != null) {
				var root = doc->get_root_element ();
				if (root != null) {
					var t_content = fixed_paragraphs;
					remove_tags_handler (root, out t_content);
					fixed_paragraphs = t_content;
				}
			}
			delete doc;
		}

		return restore_entities (fixed_paragraphs);
	}

	private static void remove_tags_handler (Xml.Node* root, out string content) {
		content = "";
		switch (root->name) {
			case "br":
				content += "\n";
				break;
			case "text":
				if (root->content != null)
					content += GLib.Markup.escape_text (root->content);
				break;
			default:
				for (var iter = root->children; iter != null; iter = iter->next) {
					var t_content = "";
					remove_tags_handler (iter, out t_content);
					content += t_content;
				}
				if (root->name == "p") content += "\n";

				break;
		}
	}

	public static string simplify (string str) {
		var simplified = str;
		if (simplified != "") {
			var doc = Html.Doc.read_doc (str, "", "utf8");
			if (doc != null) {
				var root = doc->get_root_element ();
				if (root != null) {
					var t_content = simplified;
					simplify_handler (root, out t_content);
					simplified = t_content;
				}
			}
			delete doc;
		}

		return simplified.strip ();
	}

	private static void simplify_handler (Xml.Node* root, out string content) {
		content = "";
		switch (root->name) {
			case "a":
				var href = root->get_prop ("href");
				if (href != null) {
					content += @"<a href='$(GLib.Markup.escape_text (href))'>";
					for (var iter = root->children; iter != null; iter = iter->next) {
						var t_content = "";
						simplify_handler (iter, out t_content);
						content += t_content;
					}
					content += "</a>";
				}
				break;
			case "br":
				content += "\n";
				break;
			case "text":
				if (root->content != null)
					content += GLib.Markup.escape_text (root->content);
				break;
			default:
				for (var iter = root->children; iter != null; iter = iter->next) {
					var t_content = "";
					simplify_handler (iter, out t_content);
					content += t_content;
				}
				if (root->name == "p") content += "\n\n";

				break;
		}
	}

	public static string replace_with_pango_markup (string str) {
		var res = str
			.replace ("<strong>", "<b>")
			.replace ("</strong>", "</b>")
			.replace ("<em>", "<i>")
			.replace ("</em>", "</i>")
			//  .replace("<code>", "<span font_family=\"monospace\">")
			//  .replace("</code>", "</span>\n")
			.replace ("<del>", "<s>")
			.replace ("</del>", "</s>");

		if ("<br" in str) res = res.replace ("\n", "");
		return res;
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
