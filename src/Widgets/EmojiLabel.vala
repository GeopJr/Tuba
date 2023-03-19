using Gtk;
using Gee;

public class Tooth.Widgets.EmojiLabel : Box {
	public Gee.HashMap<string, string>? instance_emojis { get; set; default = null; }
	public bool labels_should_markup { get; set; default = false; }
	public Gee.ArrayList<string> label_css_classes { get; set; default = new Gee.ArrayList<string>(); }

    private string _label = "";
	public string label { get {return _label;}
	 set {
		var w = get_first_child ();
		while(w != null) {
			remove(w);
			w = get_first_child ();
		}
		_label = value;

		generate_box();
	} }

	construct {
		orientation = Orientation.HORIZONTAL;
		spacing = 1;
	}

	public EmojiLabel(string? text = null, Gee.HashMap<string, string>? emojis = null, bool should_markup = false) {
		if (text != null) {
			instance_emojis = emojis;
			labels_should_markup = should_markup;
			label = text;

			generate_box();
		}
	}

	private void generate_box() {
		string? t_label = null;
		string[] array_label_css_classes = {};

		label_css_classes.foreach (css_class => {
			array_label_css_classes += css_class;
			return true;
		});

		if (label.contains(":") && instance_emojis != null) {
			string[] emoji_arr = custom_emoji_regex.split (label);

			t_label = "";
			foreach (unowned string str in emoji_arr) {
				// If str is an available emoji
				string? shortcode = str.length > 2 ? str.slice(1,-1) : null;
				if (shortcode != null && instance_emojis.has_key(shortcode)) {
					var tmp_child = new Label (t_label) {
						xalign = 0,
						wrap = true,
						wrap_mode = Pango.WrapMode.WORD_CHAR,
						justify = Justification.LEFT,
						single_line_mode = false,
						use_markup = false,
						css_classes = array_label_css_classes
					};
					append(tmp_child);
					t_label = "";
					append(new Widgets.Emoji(instance_emojis.get(shortcode)));
				} else {
					t_label += str;
				}
			}
		}  else {
			t_label = label;
		}

		// Label after last emoji OR label without emojis
		if (t_label != "") {
			var tmp_child = new Label (t_label) {
				xalign = 0,
				wrap = true,
				wrap_mode = Pango.WrapMode.WORD_CHAR,
				justify = Justification.LEFT,
				single_line_mode = false,
				use_markup = t_label != label ? false : labels_should_markup,
				css_classes = array_label_css_classes
			};
			append(tmp_child);
		}
	}
}
