public class Tuba.Widgets.PreviewCard : Gtk.Button {
    construct {
        this.css_classes = {"preview_card", "frame"};
    }

    public PreviewCard (API.PreviewCard card_obj) {
        var is_video = card_obj.kind == "video";

		Gtk.Widget card_container = new Gtk.Grid ();

		if (is_video)
			card_container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

		if (card_obj.image != null) {
			var image = new Gtk.Picture () {
				width_request = 25
			};

			#if GTK_4_8
				image.set_property ("content-fit", 2);
			#endif

			image_cache.request_paintable (card_obj.image, (is_loaded, paintable) => {
				image.paintable = paintable;
			});

			if (is_video) {
				image.height_request = 250;
				image.add_css_class ("preview_card_video");

				var overlay = new Gtk.Overlay () {
					vexpand = true,
					hexpand = true
				};

				var icon = new Gtk.Image () {
					valign = Gtk.Align.CENTER,
					halign = Gtk.Align.CENTER,
					css_classes = {"osd", "circular", "attachment-overlay-icon"},
					icon_name = "media-playback-start-symbolic",
					icon_size = Gtk.IconSize.LARGE
				};

				overlay.add_overlay (icon);
				overlay.child = image;
				((Gtk.Box) card_container).append (overlay);
			} else {
				image.height_request = 70;
				image.add_css_class ("preview_card_image");
				((Gtk.Grid) card_container).attach (image, 1, 1);
			}

		} else if (!is_video) {
			((Gtk.Grid) card_container).attach (new Gtk.Image.from_icon_name ("tuba-paper-symbolic") {
				height_request = 70,
				width_request = 70,
				icon_size = Gtk.IconSize.LARGE
			}, 1, 1);
		}

		var body = new Gtk.Box (Gtk.Orientation.VERTICAL, 3) {
			margin_top = 12,
			margin_bottom = 12,
			margin_end = 12,
			margin_start = 12,
			valign = Gtk.Align.CENTER
		};

		var author = card_obj.provider_name;
		if (author == "") {
			try {
				var uri = GLib.Uri.parse (card_obj.url, GLib.UriFlags.NONE);
				var host = uri.get_host ();
				if (host != null) author = host;
			} catch {}
		}

		var author_label = new Gtk.Label (author) {
			ellipsize = Pango.EllipsizeMode.END,
			halign = Gtk.Align.START,
			css_classes = {"dim-label", "caption"},
			tooltip_text = author,
			single_line_mode = true
		};
		body.append (author_label);

		if (card_obj.title != "") {
			var title_label = new Gtk.Label (card_obj.title) {
				ellipsize = Pango.EllipsizeMode.END,
				halign = Gtk.Align.FILL,
				xalign = 0.0f,
				tooltip_text = card_obj.title,
				lines = 2,
				wrap = true,
				wrap_mode = Pango.WrapMode.WORD_CHAR
			};
			body.append (title_label);
		}

        Gtk.Label? description_label = null;
		if (card_obj.description != "") {
			description_label = new Gtk.Label (card_obj.description) {
				ellipsize = Pango.EllipsizeMode.END,
				halign = Gtk.Align.FILL,
				xalign = 0.0f,
				css_classes = {"caption"},
				tooltip_text = card_obj.description,
				single_line_mode = true
			};
			body.append (description_label);
		}

        if (card_obj.kind == "link" && card_obj.history != null && card_obj.history.size > 0) {
				this.remove_css_class ("frame");
				this.add_css_class ("flat");
				this.add_css_class ("explore");

				this.clicked.connect (() => Host.open_uri (card_obj.url));

                if (description_label != null) {
                    if (description_label.label.length > 109)
                        description_label.label = description_label.label.replace ("\n", " ").substring (0, 109) + "…";
                    description_label.single_line_mode = false;
					description_label.ellipsize = Pango.EllipsizeMode.NONE;
					description_label.wrap = true;
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
                    halign = Gtk.Align.START,
                    css_classes = {"dim-label", "caption"},
					wrap = true
                };

                body.append (used_times_label);
        }

		if (is_video) {
			((Gtk.Box) card_container).append (body);
		} else {
			((Gtk.Grid) card_container).attach (body, 2, 1, 2);
		}

		this.child = card_container;
    }
}
