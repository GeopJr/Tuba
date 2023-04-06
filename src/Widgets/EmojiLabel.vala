using Gtk;
using Gee;

public class Tuba.Widgets.EmojiLabel : Tuba.Widgets.LabelWithWidgets {
	public Gee.HashMap<string, string>? instance_emojis { get; set; default = null; }

    private string _content = "";
	public string content { get {return _content;}
	 set {
		_content = value;

        string t_value;
        Gtk.Widget[] t_widgets;
        generate_label_with_emojis(value, out t_value, out t_widgets);

        set_children(t_widgets);
        text = t_value;
	} }

	construct { }

	public EmojiLabel(string? text = null, Gee.HashMap<string, string>? emojis = null) {
        Object  ();
		if (text == null) return;

		instance_emojis = emojis;

        content = text;
	}

    private void generate_label_with_emojis (string t_input, out string t_input_with_placeholder, out Gtk.Widget[] t_widgets) {
        t_input_with_placeholder = t_input;
        t_widgets = {};

		if (!t_input.contains(":") || instance_emojis == null) return;

        Gtk.Widget[] t_t_widgets = {};

		string[] emoji_arr = custom_emoji_regex.split (t_input);
        foreach (unowned string str in emoji_arr) {
			// If str is an available emoji
			string? shortcode = str.length > 2 ? str.slice(1,-1) : null;
			if (shortcode != null && instance_emojis.has_key(shortcode)) {
                t_t_widgets += new Widgets.Emoji(instance_emojis.get(shortcode));
                t_input_with_placeholder = t_input_with_placeholder.replace(@":$shortcode:", "<widget>");
			}
		}

        t_widgets = t_t_widgets;
    }
}
