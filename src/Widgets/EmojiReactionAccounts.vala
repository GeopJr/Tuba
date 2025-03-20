public class Tuba.Widgets.EmojiReactionAccounts : Adw.ExpanderRow {
	public class AccountRow : Gtk.ListBoxRow {
		API.Account account;
		Adw.Avatar avi;

		public AccountRow (API.Account account) {
			this.activatable = false;
			this.account = account;
			var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
				vexpand = true,
				margin_bottom = 12,
				margin_end = 12,
				margin_start = 12,
				margin_top = 12
			};
			avi = new Adw.Avatar (36, null, true);
			avi.name = account.display_name;
			main_box.prepend (avi);

			var info_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
				hexpand = true
			};
			var title_label = new Widgets.EmojiLabel () {
				use_markup = false
			};
			title_label.instance_emojis = account.emojis_map;
			title_label.content = account.display_name;
			info_box.prepend (title_label);
			info_box.append (new Gtk.Label (account.full_handle) {
				hexpand = true,
				xalign = 0.0f,
				wrap = true,
				wrap_mode = Pango.WrapMode.WORD_CHAR,
				use_markup = false,
				css_classes = {"dim-label"}
			});
			main_box.append (info_box);

			var open_button = new Gtk.Button.with_label (_("Open")) {
				valign = Gtk.Align.CENTER
			};
			open_button.clicked.connect (open);
			main_box.append (open_button);
			this.child = main_box;

			Tuba.Helper.Image.request_paintable (account.avatar, null, false, on_avi_cache_response);
		}

		void open () {
			this.account.open ();
		}

		void on_avi_cache_response (Gdk.Paintable? data) {
			avi.custom_image = data;
		}
	}

	public EmojiReactionAccounts (API.EmojiReaction reaction) {
		this.add_css_class ("emoji-reaction-expander");

		this.title = GLib.ngettext (
			// translators: the variable is the amount of emoji reactions, e.g. '4 Reactions'.
			//				A reaction is not the same as a favorite or a boost,
			//				see https://github.com/glitch-soc/mastodon/pull/2462
			"%d Reaction", "%d Reactions",
			(ulong) reaction.accounts.size
		).printf (reaction.accounts.size);

		if (reaction.url != null) {
			this.add_prefix (new Widgets.Emoji (reaction.url));
		} else {
			this.add_prefix (new Gtk.Label (reaction.name));
		}

		foreach (var account in reaction.accounts) {
			this.add_row (new AccountRow (account));
		}
	}
}
