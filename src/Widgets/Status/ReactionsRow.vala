public class Tuba.Widgets.ReactionsRow : Adw.Bin {
	Adw.WrapBox reaction_box;
	Gee.HashMap<string, Widgets.ReactButton> react_btn_list;
	Gtk.MenuButton emoji_button;
	Gtk.MenuButton? custom_emoji_button;

	private bool _is_announcement = false;
	public bool is_announcement {
		get { return _is_announcement; }
		set {
			emoji_button.visible = !value;
			if (custom_emoji_button != null) custom_emoji_button.visible = !value;
			_is_announcement = value;
		}
	}

	private bool can_add_reaction {
		set {
			emoji_button.sensitive = value;
			if (custom_emoji_button != null) custom_emoji_button.sensitive = value;

			react_btn_list.foreach (e => {
				if (!((Widgets.ReactButton) e.value).has_reacted) {
					((Widgets.ReactButton) e.value).sensitive = value;
				}

				return true;
			});
		}
	}

	construct {
		react_btn_list = new Gee.HashMap<string, Widgets.ReactButton> ();
		reaction_box = new Adw.WrapBox () {
			child_spacing = 6,
			line_spacing = 6,
			justify = Adw.JustifyMode.NONE,
			align = 0.0f
		};

		this.child = reaction_box;

		var emoji_picker = new Gtk.EmojiChooser ();
		emoji_button = new Gtk.MenuButton () {
			icon_name = "tuba-smile-symbolic",
			popover = emoji_picker,
			tooltip_text = _("Emoji Picker")
		};
		reaction_box.append (emoji_button);
		emoji_picker.emoji_picked.connect (on_emoji_picked);

		if (accounts.active.instance_emojis != null && accounts.active.instance_emojis.size > 0) {
			var custom_emoji_picker = new Widgets.CustomEmojiChooser ();
			custom_emoji_button = new Gtk.MenuButton () {
				icon_name = "tuba-cat-symbolic",
				popover = custom_emoji_picker,
				tooltip_text = _("Custom Emoji Picker")
			};

			reaction_box.append (custom_emoji_button);
			custom_emoji_picker.emoji_picked.connect (on_custom_emoji_picked);
		}
	}

	private void update_reaction_add_state () {
		if (this.is_announcement || accounts.active.instance_info == null) return;

		int64 max_reacts = accounts.active.instance_info.compat_status_reactions_max;
		if (max_reacts == 0) return;

		int self_reacts = 0;
		react_btn_list.foreach (e => {
			if (((Widgets.ReactButton) e.value).has_reacted) {
				self_reacts += 1;
				if (self_reacts >= max_reacts) return false;
			}

			return true;
		});

		this.can_add_reaction = self_reacts < max_reacts;
	}

	private Gee.ArrayList<API.EmojiReaction>? reactions {
		set {
			if (value == null) return;

			react_btn_list.foreach (e => {
				reaction_box.remove ((Widgets.ReactButton) e.value);

				return true;
			});
			react_btn_list.clear ();

			for (int j = value.size - 1; j >= 0; j--) {
				API.EmojiReaction p = value.get (j);
				if (p.count <= 0) return;

				var badge_button = new Widgets.ReactButton (p);
				badge_button.reaction_toggled.connect (on_reaction_toggled);
				badge_button.removed.connect (on_remove_and_update_state);

				reaction_box.prepend (badge_button);
				react_btn_list.set (p.name, badge_button);
			}

			update_reaction_add_state ();
		}
	}

	public void update_reactions_diff (Gee.ArrayList<API.EmojiReaction> new_reactions) {
		string[] new_reactions_keys = {};
		foreach (API.EmojiReaction p in new_reactions) {
			new_reactions_keys += p.name;
			if (react_btn_list.has_key (p.name)) {
				react_btn_list.get (p.name).update_reaction (p);
			} else {
				add_emoji (p);
			}
		}

		react_btn_list.foreach (e => {
			if (!((string) e.key in new_reactions_keys)) {
				on_remove ((Widgets.ReactButton) e.value);
			}

			return true;
		});

		update_reaction_add_state ();
	}

	string status_id;
	public ReactionsRow (string status_id, Gee.ArrayList<API.EmojiReaction> reactions, bool is_announcement = false) {
		this.is_announcement = is_announcement;
		this.status_id = status_id;
		this.reactions = reactions;
	}

	private void on_reaction_toggled (ReactButton btn) {
		on_reaction_toggled_real.begin (btn);
	}

	private async void on_reaction_toggled_real (ReactButton btn) {
		btn.sensitive = false;

		var req = reaction_request (btn.shortcode, btn.has_reacted);
		req.account = accounts.active;

		try {
			yield req.exec (null);
			btn.update_reacted (!btn.has_reacted);
			btn.sensitive = true;
		} catch (Error e) {
			warning (@"Error while reacting to $status_id with $(btn.shortcode): $(e.code) $(e.message)");
			btn.sensitive = true;

			app.toast ("%s: %s".printf (_("Error"), e.message));
			update_reaction_add_state ();
		}
	}

	private void react_with_shortcode (string shortcode) {
		react_with_shortcode_real.begin (shortcode);
	}

	private async void react_with_shortcode_real (string shortcode) {
		if (react_btn_list.has_key (shortcode)) {
			yield on_reaction_toggled_real (react_btn_list.get (shortcode));
		} else {
			var req = reaction_request (shortcode, false);
			req.account = accounts.active;

			try {
				var in_stream = yield req.exec (null);
				if (!this.is_announcement) {
					Json.Parser parser = yield Network.get_parser_from_inputstream_async (in_stream);
					var node = network.parse_node (parser);
					var status = API.Status.from (node);
					if (status.formal.compat_status_reactions != null) {
						update_reactions_diff (status.formal.compat_status_reactions);
					}
				}
			} catch (Error e) {
				warning (@"Error while reacting to $status_id with $(shortcode): $(e.code) $(e.message)");
				app.toast ("%s: %s".printf (_("Error"), e.message));
			}
		}
	}

	private RequestV2 reaction_request (string shortcode, bool has_reacted) {
		if (this.is_announcement) {
			string endpoint = @"/api/v1/announcements/$status_id/reactions/$(Uri.escape_string(shortcode))";
			return has_reacted ? new RequestV2 (endpoint, DELETE) : new RequestV2 (endpoint, PUT);
		} else if (accounts.active.instance_info.pleroma != null) {
			string endpoint = @"/api/v1/pleroma/statuses/$status_id/reactions/$(Uri.escape_string(shortcode))";
			return has_reacted ? new RequestV2 (endpoint, DELETE) : new RequestV2 (endpoint, PUT);
		} else {
			string action = "react";
			if (has_reacted) {
				action = "unreact";
			}

			string endpoint = @"/api/v1/statuses/$status_id/$action/$(Uri.escape_string(shortcode))";
			return new RequestV2 (endpoint, POST);
		}
	}

	private void on_remove (ReactButton btn) {
		reaction_box.remove (btn);
		react_btn_list.unset (btn.shortcode);
	}

	private void on_remove_and_update_state (ReactButton btn) {
		on_remove (btn);
		update_reaction_add_state ();
	}

	private void on_emoji_picked (string emoji) {
		react_with_shortcode (emoji);
	}

	private void on_custom_emoji_picked (string emoji_shortcode) {
		react_with_shortcode (emoji_shortcode.slice (1, -2));
	}

	private void add_emoji (API.EmojiReaction reaction) {
		if (reaction.count == 0) return;

		var badge_button = new Widgets.ReactButton (reaction);
		badge_button.reaction_toggled.connect (on_reaction_toggled);
		badge_button.removed.connect (on_remove_and_update_state);

		var last_reaction = reaction_box.get_last_child ();
		if (last_reaction != null) {
			last_reaction = last_reaction.get_prev_sibling ();

			if (last_reaction != null && custom_emoji_button != null)
				last_reaction = last_reaction.get_prev_sibling ();
		}

		if (last_reaction == null) {
			reaction_box.prepend (badge_button);
		} else {
			reaction_box.insert_child_after (badge_button, last_reaction);
		}

		react_btn_list.set (reaction.name, badge_button);
	}
}
