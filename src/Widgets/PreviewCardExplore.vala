[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/widgets/preview_card_explore.ui")]
public class Tuba.Widgets.PreviewCardExplore : Gtk.ListBoxRow {
	~PreviewCardExplore () {
		debug ("Destroying PreviewCardExplore");
	}

	static construct {
		typeof (Widgets.PreviewCardInternal).ensure ();
	}

	[GtkChild] unowned Widgets.PreviewCardInternal box;

	private string url;
	public signal void open ();

	public PreviewCardExplore (API.PreviewCard card_obj) {
		this.url = card_obj.url;
		this.activate.connect (on_card_click);
		this.open.connect (on_card_click);

		Gtk.Widget image_widget;
		if (card_obj.image != null) {
			image_widget = new Gtk.Picture () {
				width_request = 25,
				content_fit = Gtk.ContentFit.COVER,
				height_request = 250,
				css_classes = {"preview_card_h"}
			};

			Tuba.Helper.Image.request_paintable (card_obj.image, card_obj.blurhash, false, (paintable) => {
				((Gtk.Picture) image_widget).paintable = paintable;
			});
		} else {
			image_widget = new Gtk.Image.from_icon_name ("tuba-earth-symbolic") {
				css_classes = {"preview_card_h"},
				icon_size = Gtk.IconSize.LARGE,
				width_request = 70,
			};
		}
		image_widget.height_request = 70;
		box.prepend (image_widget);

		var author = card_obj.provider_name;
		if (author == "") {
			try {
				var uri = GLib.Uri.parse (card_obj.url, GLib.UriFlags.NONE);
				var host = uri.get_host ();
				if (host != null) author = host;
			} catch {}
		}
		box.author_label.label = author;

		if (card_obj.title != "") {
			box.title_label.label = box.title_label.tooltip_text = card_obj.title.replace ("\n", " ").strip ();
			box.title_label.visible = true;
		}

		if (card_obj.description != "") {
			box.description_label.label = box.description_label.tooltip_text = card_obj.description;
			box.description_label.visible = true;
			box.description_label.single_line_mode = false;
			box.description_label.ellipsize = Pango.EllipsizeMode.NONE;
			box.description_label.wrap = true;
			box.description_label.wrap_mode = Pango.WrapMode.WORD_CHAR;

			if (box.description_label.label.length > 109)
						box.description_label.label = box.description_label.label.replace ("\n", " ").substring (0, 109) + "…";
		}


		var last_history_entry = card_obj.history.get (0);
		var total_uses = int.parse (last_history_entry.uses);
		var total_accounts = int.parse (last_history_entry.accounts);
		// translators: the variables are numbers
		var subtitle = _("Discussed %d times by %d people yesterday").printf (total_uses, total_accounts);

		if (card_obj.history.size > 1) {
			last_history_entry = card_obj.history.get (1);
			total_uses += int.parse (last_history_entry.uses);
			total_accounts += int.parse (last_history_entry.accounts);

			// translators: the variables are numbers
			subtitle = _("Discussed %d times by %d people in the past 2 days")
				.printf (total_uses, total_accounts);
		}

		var used_times_label = new Gtk.Label (subtitle) {
			xalign = 0.0f,
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			css_classes = { "caption" }
		};

		if (accounts.active.instance_info.tuba_api_versions.mastodon >= 1) {
			Gtk.Button discussions_button = new Gtk.Button () {
				margin_top = 6,
				child = used_times_label,
				// translators: tooltip text on 'explore' tab button to
				//				see posts where the selected article is
				//				being discussed.
				tooltip_text = _("See Discussions"),

				// Looks weird flat, as it doesn't indicate
				// that it's clickable, plus it's not dimmed and
				// has padding. Looks out of place.
				//  css_classes = { "flat" },
			};
			discussions_button.clicked.connect (on_link_timeline_open);
			box.internal_box.append (discussions_button);
		} else {
			used_times_label.add_css_class ("dim-label");
			box.internal_box.append (used_times_label);
		}
	}

	private void on_link_timeline_open () {
		app.main_window.open_view (new Views.Link (this.url));
	}

	private void on_card_click () {
		Host.open_url.begin (this.url);
	}
}
