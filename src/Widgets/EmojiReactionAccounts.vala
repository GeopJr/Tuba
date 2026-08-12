public class Tuba.Widgets.EmojiReactionAccounts : Adw.ExpanderRow {
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
			this.add_row (new Widgets.AccountRow (account));
		}
	}
}
