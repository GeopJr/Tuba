[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/widgets/preview_card.ui")]
public class Tuba.Widgets.PreviewCard : Gtk.Button {
    construct {
        this.css_classes = {"preview_card", "flat"};
    }

	[GtkChild] unowned Gtk.Box box;
    [GtkChild] unowned Gtk.Label author_label;
    [GtkChild] unowned Gtk.Label title_label;
    [GtkChild] unowned Gtk.Label description_label;
    [GtkChild] unowned Gtk.Label used_times_label;

    public PreviewCard (API.PreviewCard card_obj) {
        var is_video = card_obj.kind == "video";

		if (is_video) {
			box.orientation = Gtk.Orientation.VERTICAL;
			box.homogeneous = false;
		}

		Gtk.Widget image_widget;
		if (card_obj.image != null) {
			var image = new Gtk.Picture () {
				width_request = 25,
				content_fit = Gtk.ContentFit.COVER
			};

			Tuba.Helper.Image.request_paintable (card_obj.image, card_obj.blurhash, (paintable) => {
				image.paintable = paintable;
			});

			if (is_video) {
				image.height_request = 250;
				image.add_css_class ("preview_card_video");

				var overlay = new Gtk.Overlay () {
					vexpand = true,
					hexpand = true,
					child = image
				};

				overlay.add_overlay (new Gtk.Image () {
					valign = Gtk.Align.CENTER,
					halign = Gtk.Align.CENTER,
					css_classes = {"osd", "circular", "attachment-overlay-icon"},
					icon_name = "tuba-play-large-symbolic",
					icon_size = Gtk.IconSize.LARGE
				});

				image_widget = overlay;
			} else {
				image.height_request = 70;
				image.add_css_class ("preview_card_image");

				image_widget = image;
			}
		} else {
			image_widget = new Gtk.Image.from_icon_name (
				is_video ? "tuba-play-large-symbolic" : "tuba-earth-symbolic"
			) {
				height_request = 70,
				width_request = 70,
				icon_size = Gtk.IconSize.LARGE
			};
			image_widget.add_css_class ("preview_card_image");

			box.orientation = Gtk.Orientation.HORIZONTAL;
			box.homogeneous = false;
		}
		box.prepend (image_widget);

		var author = card_obj.provider_name;
		if (author == "") {
			try {
				var uri = GLib.Uri.parse (card_obj.url, GLib.UriFlags.NONE);
				var host = uri.get_host ();
				if (host != null) author = host;
			} catch {}
		}
		author_label.label = author;

		if (card_obj.title != "") {
			title_label.label = title_label.tooltip_text = card_obj.title.strip ();
			title_label.visible = true;
		}

		if (card_obj.description != "") {
			description_label.label = description_label.tooltip_text = card_obj.description;
			description_label.visible = true;
		}

        if (card_obj.kind == "link" && card_obj.history != null && card_obj.history.size > 0) {
				this.add_css_class ("explore");

				this.clicked.connect (() => Host.open_uri (card_obj.url));

                if (description_label.visible) {
                    if (description_label.label.length > 109)
                        description_label.label = description_label.label.replace ("\n", " ").substring (0, 109) + "…";
                    description_label.single_line_mode = false;
					description_label.ellipsize = Pango.EllipsizeMode.NONE;
					description_label.wrap = true;
					description_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
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

				used_times_label.label = subtitle;
				used_times_label.visible = true;
        }
    }
}
