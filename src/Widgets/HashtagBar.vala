public class Tuba.Widgets.HashtagBar : Adw.Bin {
	const int MAX_VISIBLE_TAGS = 3;

	public class HashtagButton : Gtk.Button {
		construct {
			this.clicked.connect (on_clicked);
			this.css_classes = { "profile-role-border-radius", "hashtag-bar-hashtag" };
		}

		string tag;
		public HashtagButton (TagExtractor.Tag hashtag) {
			tag = hashtag.tag;
			this.label = @"#$tag";
		}

		private void on_clicked () {
			app.main_window.open_view (new Views.Hashtag (tag, null, Uri.escape_string (tag)));
		}
	}

	Adw.WrapBox flowbox;
	Gtk.Button show_more;
	construct {
		flowbox = new Adw.WrapBox () {
			//  selection_mode = Gtk.SelectionMode.NONE,
			child_spacing = 6,
			line_spacing = 6,
			//  max_children_per_line = 100
		};

		this.child = flowbox;
	}

	public HashtagBar (TagExtractor.Tag[] tags) {
		bool should_show_all = tags.length <= MAX_VISIBLE_TAGS + 1;

		for (int i = 0; i < tags.length; i++) {
			flowbox.append (
				new HashtagButton (tags [i]) {
					visible = should_show_all || i < MAX_VISIBLE_TAGS
				}
			);
		}

		if (!should_show_all) {
			// translators: the variable is a number. This is used in a button that shows
			//				all post hashtags when clicked.
			show_more = new Gtk.Button.with_label (_("Show %d More").printf (tags.length - MAX_VISIBLE_TAGS)) {
				css_classes = { "flat", "profile-role-border-radius", "hashtag-bar-hashtag" }
			};
			show_more.clicked.connect (on_clicked);

			flowbox.append (show_more);
		}
	}

	private void on_clicked () {
		flowbox.remove (show_more);

		int i = 0;
		var w = this.get_first_child ();
		while (w != null) {
			if (i >= MAX_VISIBLE_TAGS) w.visible = true;

			i = i + 1;
			w = w.get_next_sibling ();
		};
	}
}
