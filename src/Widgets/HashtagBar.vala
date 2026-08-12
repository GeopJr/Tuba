public class Tuba.Widgets.HashtagBar : Adw.Bin {
	const int MAX_VISIBLE_TAGS = 3;

	public class HashtagButton : Gtk.Button {
		construct {
			this.clicked.connect (on_clicked);
			this.css_classes = { "tuba-circular", "hashtag-bar-hashtag", "font-small" };
		}

		string tag;
		public HashtagButton (Utils.TagExtractor.Tag hashtag) {
			tag = hashtag.tag;
			this.child = new Gtk.Label (@"#$tag") {
				ellipsize = Pango.EllipsizeMode.END
			};
		}

		private void on_clicked () {
			app.main_window.open_view (new Views.Hashtag (tag, null, Uri.escape_string (tag)));
		}
	}

	Adw.WrapBox wrapbox;
	Gtk.Button show_more;
	construct {
		wrapbox = new Adw.WrapBox () {
			child_spacing = 6,
			line_spacing = 6,
			justify = Adw.JustifyMode.NONE,
			align = 0.0f
		};

		this.child = wrapbox;
	}

	public HashtagBar (Utils.TagExtractor.Tag[] tags) {
		bool should_show_all = tags.length <= MAX_VISIBLE_TAGS + 1;

		for (int i = 0; i < tags.length; i++) {
			wrapbox.append (
				new HashtagButton (tags [i]) {
					visible = should_show_all || i < MAX_VISIBLE_TAGS
				}
			);
		}

		if (!should_show_all) {
			// translators: the variable is a number. This is used in a button that shows
			//				all post hashtags when clicked.
			show_more = new Gtk.Button.with_label (_("Show %d More").printf (tags.length - MAX_VISIBLE_TAGS)) {
				css_classes = { "flat", "tuba-circular", "hashtag-bar-hashtag", "font-small" }
			};
			show_more.clicked.connect (on_clicked);

			wrapbox.append (show_more);
		}
	}

	private void on_clicked () {
		wrapbox.remove (show_more);

		var w = wrapbox.get_first_child ();
		while (w != null) {
			if (!w.visible) w.visible = true;
			w = w.get_next_sibling ();
		};
	}

	public void to_display_only () {
		var w = wrapbox.get_first_child ();
		while (w != null) {
			if (w is HashtagButton) {
				w.can_target =
				w.can_focus =
				w.focusable = false;
			}
			w = w.get_next_sibling ();
		};
	}
}
