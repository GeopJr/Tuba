public class Tuba.Widgets.MarkupView : Gtk.Box {

	public delegate void NodeFn (Xml.Node* node);
	public delegate void NodeHandlerFn (MarkupView view, Xml.Node* node);

	string? current_chunk = null;

	string _content = "";
	public string content {
		get {
			return _content;
		}
		set {
			_content = value;
			update_content (_content);
		}
	}

	public GLib.Regex? bold_text_regex { get; set; default = null; }
	public Gee.HashMap<string, string>? instance_emojis { get; set; default = null; }
	public weak Gee.ArrayList<API.Mention>? mentions { get; set; default = null; }
	public bool has_quote { get; set; default=false; }
	public bool extract_last_tags { get; set; default=false; }
	public bool has_link { get; set; default=false; }

	TagExtractor.Tag[]? extracted_tags = null;
	public TagExtractor.Tag[]? get_extracted_tags () {
		return extracted_tags;
	}

	private bool _selectable = false;
	public bool selectable {
		get { return _selectable; }
		set {
			_selectable = value;

			var w = this.get_first_child ();
			while (w != null) {
				var label = w as RichLabel;
				if (label != null) {
					label.selectable = _selectable;
				}
				w = w.get_next_sibling ();
			};
		}
	}

	static construct {
		set_accessible_role (Gtk.AccessibleRole.GENERIC);
	}

	construct {
		this.focusable = true;
		orientation = Gtk.Orientation.VERTICAL;
		spacing = 12;
	}

	void update_aria () {
		string total_aria = "";

		var w = this.get_first_child ();
		while (w != null) {
			var label = w as RichLabel;
			if (label != null) {
				total_aria += @"\n$(label.accessible_text)";
			}
			w = w.get_next_sibling ();
		};

		this.update_property (Gtk.AccessibleProperty.LABEL, total_aria, -1);
		this.update_property (Gtk.AccessibleProperty.DESCRIPTION, null, -1);
	}

	void update_content (string content) {
		current_chunk = null;
		extracted_tags = null;
		has_link = false;

		for (var w = get_first_child (); w != null; w = w.get_next_sibling ()) {
			w.unparent ();
			w.destroy ();
		}

		string to_parse = HtmlUtils.replace_with_pango_markup (content);
		if (to_parse == "") return;

		var doc = Html.Doc.read_doc (to_parse, "", "utf8");
		if (doc != null) {
			var root = doc->get_root_element ();
			if (root != null) {
				default_handler (this, root);
			}
		}

		delete doc;

		visible = get_first_child () != null;
		update_aria ();
	}

	static void traverse (Xml.Node* root, owned NodeFn cb) {
		for (var iter = root->children; iter != null; iter = iter->next) {
			cb (iter);
		}
	}

	static void traverse_and_handle (MarkupView v, Xml.Node* root, owned NodeHandlerFn handler) {
		traverse (root, node => {
			handler (v, node);
		});
	}

	void extract_tags () {
		if (current_chunk == null || !this.has_link) return;
		var extracted = TagExtractor.from_string (current_chunk);
		if (extracted.input_without_tags == null || extracted.extracted_tags == null) return;

		current_chunk = extracted.input_without_tags;
		extracted_tags = extracted.extracted_tags;
	}

	void commit_chunk () {
		if (current_chunk != null && current_chunk != "") {
			var label = new RichLabel () {
				visible = true,
				// markup = MarkupPolicy.TRUST,
				selectable = _selectable,
				vexpand = true,
				large_emojis = settings.enlarge_custom_emojis,
				use_markup = true,
				fix_overflow_hack = true,
				//  focusable_label = true
			};
			if (instance_emojis != null) label.instance_emojis = instance_emojis;
			if (mentions != null) label.mentions = mentions;

			label.label = current_chunk.strip ();
			append (label);
		}
		current_chunk = null;
	}

	void write_chunk (string? chunk) {
		if (chunk == null) return;

		if (current_chunk == null)
			current_chunk = chunk;
		else
			current_chunk += chunk;
	}

	void strip_chunk () {
		if (current_chunk != null)
			current_chunk = current_chunk.strip ();
	}

	bool chunk_ends_in_newline () {
		if (current_chunk == null) return false;
		return current_chunk.has_suffix ("\n");
	}

	static string blockquote_handler_text = "";
	private static void blockquote_handler (Xml.Node* root, GLib.Regex? bold_text_regex = null) {
		traverse (root, (node) => {
			switch (node->name) {
				case "text":
					blockquote_handler_text += bold_needle (GLib.Markup.escape_text (node->content), bold_text_regex);
					break;
				case "html":
				case "span":
				case "markup":
				case "pre":
				case "body":
				case "p":
					blockquote_handler (node, bold_text_regex);
					break;
				case "b":
				case "i":
				case "u":
				case "s":
				case "sup":
				case "sub":
					blockquote_handler_text += @"<$(node->name)>";
					blockquote_handler (node, bold_text_regex);
					blockquote_handler_text += @"</$(node->name)>";
				break;
				case "code":
					blockquote_handler_text += "<span font_family=\"monospace\">";
					blockquote_handler (node, bold_text_regex);
					blockquote_handler_text += "</span>";
					break;
				case "a":
					var href = node->get_prop ("href");
					if (href != null) {
						blockquote_handler_text += "<a href='" + GLib.Markup.escape_text (href) + "'>";
						blockquote_handler (node, bold_text_regex);
						blockquote_handler_text += "</a>";
					}
					break;
				case "ol":
					int li_count = 1;
					for (var iter = node->children; iter != null; iter = iter->next) {
						if (iter->name == "li") {
							blockquote_handler_text += @"\n$li_count. ";
							blockquote_handler (iter, bold_text_regex);

							li_count++;
						} else break;
					}
					blockquote_handler_text += "\n";

					break;
				case "ul":
					blockquote_handler (node, bold_text_regex);
					blockquote_handler_text += "\n";
					break;
				case "li":
					blockquote_handler_text += "\n• ";
					blockquote_handler (node, bold_text_regex);
					break;
				case "br":
					blockquote_handler_text += "\n";
					break;
				default:
					for (var iter = root->children; iter != null; iter = iter->next) {
						blockquote_handler (iter, bold_text_regex);
					}
					break;
			}
		});
	}

	public static void list_item_handler (MarkupView v, Xml.Node* root) {
		switch (root->name) {
			case "p":
				traverse_and_handle (v, root, default_handler);
				break;
			default:
				default_handler (v, root);
				break;
		}
	}

	public static void default_handler (MarkupView v, Xml.Node* root) {
		switch (root->name) {
			case "span":
				string? classes = root->get_prop ("class");
				if (!v.has_quote || classes == null || !classes.contains ("quote-inline"))
					traverse_and_handle (v, root, default_handler);
				break;
			case "html":
			case "markup":
				traverse_and_handle (v, root, default_handler);
				break;
			case "body":
				traverse_and_handle (v, root, default_handler);
				if (v.extract_last_tags) v.extract_tags ();
				v.commit_chunk ();
				break;
			case "p":
				if (root->children == null && root->content == null) break;
				if (!v.chunk_ends_in_newline ()) v.write_chunk ("\n");
				v.write_chunk ("\n");
				traverse_and_handle (v, root, default_handler);
				v.write_chunk ("\n");
				break;
			case "pre":
				if (
					root->children != null
					&& root->children->name == "code"
					&& root->children->children != null
				) {
					v.commit_chunk ();

					blockquote_handler_text = "";
					blockquote_handler (root->children, v.bold_text_regex);
					var text = blockquote_handler_text.strip ();
					var label = new RichLabel (text) {
						visible = true,
						css_classes = { "ttl-code", "monospace" },
						use_markup = true,
						fix_overflow_hack = true,
						//  focusable_label = true
						// markup = MarkupPolicy.DISALLOW
					};

					v.append (label);
				} else {
					v.write_chunk ("\n");
					traverse_and_handle (v, root, default_handler);
					v.write_chunk ("\n");
				}
				break;
			case "code":
				v.write_chunk ("<span background=\"#9696961a\" font_family=\"monospace\">");
				traverse_and_handle (v, root, default_handler);
				v.strip_chunk ();
				v.write_chunk ("</span>");
				break;
			case "blockquote":
				v.commit_chunk ();

				blockquote_handler_text = "";
				blockquote_handler (root, v.bold_text_regex);
				var text = blockquote_handler_text.strip ();
				var label = new RichLabel (text) {
					visible = true,
					css_classes = { "ttl-code", "italic" },
					use_markup = true,
					fix_overflow_hack = true,
					//  focusable_label = true
					// markup = MarkupPolicy.DISALLOW
				};
				v.append (label);
				break;
			case "a":
				var href = root->get_prop ("href");
				if (href != null) {
					v.write_chunk (@"<a href='$(GLib.Markup.escape_text (href))'>");
					traverse_and_handle (v, root, default_handler);
					v.write_chunk ("</a>");
					v.has_link = true;
				}
				break;

			case "h1":
				if (v.current_chunk != "" && v.current_chunk != null)
					v.write_chunk ("\n");
				v.write_chunk ("<b><span size=\"xx-large\">");
				traverse_and_handle (v, root, default_handler);
				v.write_chunk ("</span></b>\n");
				break;
			case "h2":
				if (v.current_chunk != "" && v.current_chunk != null)
					v.write_chunk ("\n");
				v.write_chunk ("<b><span size=\"x-large\">");
				traverse_and_handle (v, root, default_handler);
				v.write_chunk ("</span></b>\n");
				break;
			case "h3":
				if (v.current_chunk != "" && v.current_chunk != null)
					v.write_chunk ("\n");
				v.write_chunk ("<b><span size=\"large\">");
				traverse_and_handle (v, root, default_handler);
				v.write_chunk ("</span></b>\n");
				break;
			case "h4":
				if (v.current_chunk != "" && v.current_chunk != null)
					v.write_chunk ("\n");
				v.write_chunk ("<b>");
				traverse_and_handle (v, root, default_handler);
				v.write_chunk ("</b>\n");
				break;
			case "h5":
				if (v.current_chunk != "" && v.current_chunk != null)
					v.write_chunk ("\n");
				v.write_chunk ("<b><span size=\"small\">");
				traverse_and_handle (v, root, default_handler);
				v.write_chunk ("</span></b>\n");
				break;
			case "h6":
				if (v.current_chunk != "" && v.current_chunk != null)
					v.write_chunk ("\n");
				v.write_chunk ("<b><span size=\"x-small\">");
				traverse_and_handle (v, root, default_handler);
				v.write_chunk ("</span></b>\n");
				break;

			case "b":
			case "i":
			case "u":
			case "s":
			case "sup":
			case "sub":
				v.write_chunk (@"<$(root->name)>");
				traverse_and_handle (v, root, default_handler);
				v.write_chunk (@"</$(root->name)>");
			break;

			case "ol":
				int li_count = 1;
				for (var iter = root->children; iter != null; iter = iter->next) {
					if (iter->name == "li") {
						v.write_chunk (@"\n$li_count. ");
						traverse_and_handle (v, iter, list_item_handler);

						li_count++;
					} else continue;
				}
				v.write_chunk ("\n");

				break;
			case "ul":
				traverse_and_handle (v, root, default_handler);
				v.write_chunk ("\n");
				break;
			case "li":
				v.write_chunk ("\n• ");
				traverse_and_handle (v, root, list_item_handler);
				break;
			case "br":
				v.write_chunk ("\n");
				break;
			case "text":
				if (root->content != null) {
					v.write_chunk (bold_needle (GLib.Markup.escape_text (root->content), v.bold_text_regex));
				}
				break;
			default:
				warning (@"Unknown HTML tag: \"$(root->name)\"");
				traverse_and_handle (v, root, default_handler);
				break;
		}
	}

	private static string bold_needle (owned string source, GLib.Regex? bold_text_regex) {
		if (bold_text_regex == null || source.length >= 2000) return source;

		try {
			source = bold_text_regex.replace (source, source.length, 0, "<b>\\0</b>");
		} catch (RegexError e) {
			warning (@"Couldn't set search bold text: $(e.message)");
		}

		return source;
	}
}
