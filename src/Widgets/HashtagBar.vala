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

	Gtk.FlowBox flowbox;
	Gtk.Button show_more;
	construct {
		flowbox = new Gtk.FlowBox () {
			selection_mode = Gtk.SelectionMode.NONE,
			column_spacing = 6,
			row_spacing = 6,
			max_children_per_line = 100
		};

		this.child = flowbox;
	}

	public HashtagBar (TagExtractor.Tag[] tags) {
		for (int i = 0; i < tags.length; i++) {
			flowbox.append (
				new Gtk.FlowBoxChild () {
					child = new HashtagButton (tags [i]),
					visible = i < MAX_VISIBLE_TAGS,
					focusable = false
				}
			);
		}

		if (tags.length > MAX_VISIBLE_TAGS) {
			show_more = new Gtk.Button.with_label (_("Show %d More").printf (tags.length - MAX_VISIBLE_TAGS)) {
				css_classes = { "flat", "profile-role-border-radius", "hashtag-bar-hashtag" }
			};
			show_more.clicked.connect (on_clicked);

			flowbox.append (new Gtk.FlowBoxChild () {
				child = show_more,
				focusable = false
			});
		}
	}

	private void on_clicked () {
		flowbox.remove (show_more);

		int i = MAX_VISIBLE_TAGS;
		var child = flowbox.get_child_at_index (i);
		while (child != null) {
			child.visible = true;

			i = i + 1;
			child = flowbox.get_child_at_index (i);
		}
	}
}
