[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/widgets/preview_card.ui")]
public class Tuba.Widgets.PreviewCard : Gtk.Box {
	~PreviewCard () {
		debug ("Destroying PreviewCard");
	}

	static construct {
		typeof (Widgets.PreviewCardInternal).ensure ();
	}

	[GtkChild] public unowned Gtk.Button button;
	[GtkChild] unowned Widgets.PreviewCardInternal box;

	private Gee.ArrayList<API.PreviewCard.AuthorEntity>? verified_authors = null;
	private string? author_url = null;
	private API.Account? author_account = null;

	public PreviewCard (API.PreviewCard card_obj) {
		var is_video = card_obj.kind == "video";

		Gtk.Widget image_widget;
		if (card_obj.image != null) {
			var image = new Gtk.Picture () {
				width_request = 25,
				content_fit = Gtk.ContentFit.COVER,
				height_request = 250,
				css_classes = {"preview_card_v"}
			};

			Tuba.Helper.Image.request_paintable (card_obj.image, card_obj.blurhash, false, (paintable) => {
				image.paintable = paintable;
			});

			if (is_video) {
				var overlay = new Gtk.Overlay () {
					vexpand = true,
					hexpand = true,
					child = image
				};

				overlay.add_overlay (new Gtk.Image () {
					valign = Gtk.Align.CENTER,
					halign = Gtk.Align.CENTER,
					css_classes = {"osd", "circular", "attachment-overlay-icon"},
					icon_name = "media-playback-start-symbolic",
					icon_size = Gtk.IconSize.LARGE
				});

				image_widget = overlay;
			} else {
				image_widget = image;
			}
		} else {
			image_widget = new Gtk.Image.from_icon_name (
				is_video ? "media-playback-start-symbolic" : "tuba-earth-symbolic"
			) {
				css_classes = {"preview_card_h"},
				icon_size = Gtk.IconSize.LARGE,
				height_request = 70,
				width_request = 70,
			};

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
		box.author_label.label = author;

		if (card_obj.title != "") {
			box.title_label.label = box.title_label.tooltip_text = card_obj.title.replace ("\n", " ").strip ();
			box.title_label.visible = true;
		}

		if (card_obj.description != "") {
			box.description_label.label = box.description_label.tooltip_text = card_obj.description;
			box.description_label.visible = true;
		}

		if (card_obj.authors != null && card_obj.authors.size > 0) {
			bool should_add = true;

			Gtk.Widget more_from_button = new Gtk.Button () {
				halign = Gtk.Align.START,
				css_classes = { "flat", "verified-author" }
			};

			if (card_obj.authors.size == 1) {
				var verified_author = card_obj.authors.get (0);
				if (verified_author.account != null) {
					// translators: the variable is a user name. This is shown on
					//				preview cards of articles from 'verified' fedi authors.
					//				By <user>
					//				(As in, 'written by <user>')
					((Gtk.Button) more_from_button).child = new Widgets.RichLabel.with_emojis (_("By %s").printf (verified_author.account.display_name), verified_author.account.emojis_map) {
						use_markup = false,
						xalign = 0.0f
					};
					author_account = verified_author.account;

					((Gtk.Button) more_from_button).clicked.connect (open_author);
				} else if (verified_author.name != null && verified_author.name != "") {
					var verified_author_label = new Gtk.Label (_("By %s").printf (verified_author.name)) {
						xalign = 0.0f,
						wrap = true,
						wrap_mode = Pango.WrapMode.WORD_CHAR
					};

					if (verified_author.url == null || verified_author.url == "") {
						more_from_button = verified_author_label;
						more_from_button.add_css_class ("font-bold");
						more_from_button.add_css_class ("verified-author");
					} else {
						author_url = verified_author.url;
						((Gtk.Button) more_from_button).child = verified_author_label;
						((Gtk.Button) more_from_button).clicked.connect (open_author);
					}
				} else {
					should_add = false;
				}
			} else {
				((Gtk.Button) more_from_button).child = new Gtk.Label (
					// translators: the variable is a number. This is shown on
					//				preview cards of articles from 'verified' fedi authors,
					//				when there's more than 1.
					//				See all <amount> authors
					GLib.ngettext ("See %d author", "See all %d authors", (ulong) card_obj.authors.size).printf (card_obj.authors.size)
				) {
					xalign = 0.0f,
					wrap = true,
					wrap_mode = Pango.WrapMode.WORD_CHAR,
					css_classes = { "font-bold" }
				};
				verified_authors = card_obj.authors;

				((Gtk.Button) more_from_button).clicked.connect (open_authors);
			}

			if (should_add) this.append (more_from_button);
		}
	}

	private void open_author () {
		if (author_account != null) {
			author_account.open ();
		} else if (author_url != null && author_url != "") {
			Host.open_url.begin (author_url);
		}
	}

	private class AuthorRow : Gtk.ListBoxRow {
		string? callback_url = null;
		API.Account? callback_account = null;

		public AuthorRow (API.PreviewCard.AuthorEntity author_entity) {
			if (author_entity.account != null) {
				var widget = new Widgets.EmojiLabel () {
					use_markup = false,
					margin_top = 8,
					margin_start = 8,
					margin_end = 8,
					margin_bottom = 8
				};
				widget.instance_emojis = author_entity.account.emojis_map;
				widget.content = author_entity.account.display_name;
				this.child = widget;

				callback_account = author_entity.account;
				this.activatable = callback_account != null;
			} else {
				var widget = new Gtk.Label (author_entity.name) {
					xalign = 0.0f,
					wrap = true,
					wrap_mode = Pango.WrapMode.WORD_CHAR,
					margin_top = 8,
					margin_start = 8,
					margin_end = 8,
					margin_bottom = 8
				};
				this.child = widget;

				callback_url = author_entity.url;
				this.activatable = callback_url != null && callback_url != "";
			}
		}

		public void open () {
			if (callback_account != null) {
				callback_account.open ();
			} else if (callback_url != null && callback_url != "") {
				Host.open_url.begin (callback_url);
			}
		}
	}

	Gtk.Popover? authors_popover = null;
	private void open_authors (Gtk.Button btn) {
		if (authors_popover != null) return;

		var listbox = new Gtk.ListBox () {
			selection_mode = Gtk.SelectionMode.NONE,
			css_classes = { "background-none" }
		};
		listbox.row_activated.connect (on_author_row_activated);

		foreach (var author in verified_authors) {
			if (
				author.account != null
				|| (
					author.name != null
					&& author.name != ""
				)
			) listbox.append (new AuthorRow (author));
		}

		authors_popover = new Gtk.Popover () {
			child = new Gtk.ScrolledWindow () {
				child = listbox,
				hexpand = true,
				vexpand = true,
				hscrollbar_policy = Gtk.PolicyType.NEVER,
				max_content_height = 500,
				width_request = 360,
				propagate_natural_height = true
			}
		};

		authors_popover.closed.connect (clear_authors_popover);
		authors_popover.set_parent (btn);
		authors_popover.popup ();
	}

	private void clear_authors_popover () {
		if (authors_popover == null) return;

		authors_popover.unparent ();
		authors_popover.dispose ();
		authors_popover = null;
	}

	private void on_author_row_activated (Gtk.ListBoxRow row) {
		clear_authors_popover ();
		((AuthorRow) row).open ();
	}
}
