public class Tuba.Widgets.ActionsRow : Gtk.Box {
	public signal void reply (Gtk.Button btn);
	public API.Status status { get; set; }

	StatusActionButton reply_button;
	StatusActionButton reblog_button;
	StatusActionButton favorite_button;
	StatusActionButton bookmark_button;

	public ActionsRow (API.Status t_status) {
		Object (status: t_status);

		bind ();
	}

	~ActionsRow () {
		unbind ();
	}

	Binding[] bindings = {};
	ulong[] status_notify_signals = {};
	public void bind () {
		if (bindings.length != 0) return;

		bindings += this.status.bind_property ("replies-count", reply_button, "amount", GLib.BindingFlags.SYNC_CREATE);

		status_notify_signals += this.status.notify["in-reply-to-id"].connect (in_reply_to_id_notify_func);
		in_reply_to_id_notify_func ();

		status_notify_signals += this.status.notify["can-be-boosted"].connect (can_be_boosted_notify_func);
		can_be_boosted_notify_func ();

		bindings += this.status.bind_property ("can-be-boosted", reblog_button, "sensitive", BindingFlags.SYNC_CREATE);
		bindings += this.status.bind_property ("reblogged", reblog_button, "active", GLib.BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
		bindings += this.status.bind_property ("reblogs-count", reblog_button, "amount", GLib.BindingFlags.SYNC_CREATE);

		bindings += this.status.bind_property ("favourited", favorite_button, "active", GLib.BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
		bindings += this.status.bind_property ("favourites-count", favorite_button, "amount", GLib.BindingFlags.SYNC_CREATE);

		bindings += this.status.bind_property ("bookmarked", bookmark_button, "active", GLib.BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
	}

	private void in_reply_to_id_notify_func () {
		reply_button.default_icon_name = this.status.in_reply_to_id != null ? "tuba-reply-all-symbolic" : "tuba-reply-sender-symbolic";
	}

	private void can_be_boosted_notify_func () {
		bool src_val = this.status.can_be_boosted;
		reblog_button.sensitive = src_val;

		if (src_val) {
			reblog_button.tooltip_text = _("Boost");
			reblog_button.default_icon_name = "tuba-media-playlist-repeat-symbolic";
		} else {
			reblog_button.tooltip_text = _("This post can't be boosted");
			reblog_button.default_icon_name = accounts.active.visibility[this.status.visibility].icon_name;
		}
	}

	public void unbind () {
		foreach (var binding in bindings) {
			binding.unbind ();
		}

		foreach (var signal_id in status_notify_signals) {
			if (GLib.SignalHandler.is_connected (this.status, signal_id))
				this.status.disconnect (signal_id);
		}

		bindings = {};
		status_notify_signals = {};
	}

	construct {
		this.add_css_class ("ttl-post-actions");
		this.spacing = 6;

		reply_button = new StatusActionButton.with_icon_name ("tuba-reply-sender-symbolic") {
			active = false,
			css_classes = { "ttl-status-action-reply", "flat", "circular" },
			halign = Gtk.Align.START,
			hexpand = true,
			tooltip_text = _("Reply"),
			aria_label_template = (amount) => {
				// translators: Accessibility label on post buttons.
				//				The variable is a number.
				return GLib.ngettext (
					"%s Reply",
					"%s Replies",
					(ulong) amount
				).printf (amount.to_string ());
			}
		};
		reply_button.clicked.connect (on_reply_button_clicked);
		this.append (reply_button);

		reblog_button = new StatusActionButton.with_icon_name ("tuba-media-playlist-repeat-symbolic") {
			css_classes = { "ttl-status-action-reblog", "flat", "circular" },
			halign = Gtk.Align.START,
			hexpand = true,
			tooltip_text = _("Boost"),
			aria_label_template = (amount) => {
				// translators: Accessibility label on post buttons.
				//				The variable is a number.
				return GLib.ngettext (
					"%s Boost",
					"%s Boosts",
					(ulong) amount
				).printf (amount.to_string ());
			}
		};
		reblog_button.clicked.connect (on_boost_button_clicked);
		this.append (reblog_button);

		favorite_button = new StatusActionButton.with_icon_name ("tuba-unstarred-symbolic") {
			active_icon_name = "starred-symbolic",
			css_classes = { "ttl-status-action-star", "flat", "circular" },
			halign = Gtk.Align.START,
			hexpand = true,
			tooltip_text = _("Favorite"),
			aria_label_template = (amount) => {
				// translators: Accessibility label on post buttons.
				//				The variable is a number.
				return GLib.ngettext (
					"%s Favorite",
					"%s Favorites",
					(ulong) amount
				).printf (amount.to_string ());
			}
		};
		favorite_button.clicked.connect (on_favorite_button_clicked);
		this.append (favorite_button);

		bookmark_button = new StatusActionButton.with_icon_name ("tuba-bookmarks-symbolic") {
			active_icon_name = "tuba-bookmarks-filled-symbolic",
			css_classes = { "ttl-status-action-bookmark", "flat", "circular" },
			halign = Gtk.Align.START,
			hexpand = false,
			tooltip_text = _("Bookmark")
		};
		bookmark_button.clicked.connect (on_bookmark_button_clicked);
		this.append (bookmark_button);
	}

	private void on_reply_button_clicked (Gtk.Button btn) {
		if (settings.reply_to_old_post_reminder && Tuba.DateTime.is_3_months_old (status.formal.created_at)) {
			app.question.begin (
				// translators: the variable is a datetime with the "old" suffix, e.g. "5 months old", "a day old", "2 years old".
				//				The "old" suffix is translated on the datetime strings, not here
				{_("This post is %s").printf (Tuba.DateTime.humanize_old (status.formal.created_at)), false},
				// translators: you can find this string translated on https://github.com/mastodon/mastodon-android/tree/master/mastodon/src/main/res
				//				in the `strings.xml` file inside the `values-` folder that matches your locale under the `old_post_sheet_text` key
				{_("You can still reply, but it may no longer be relevant."), false},
				app.main_window,
				{ { _("Reply"), Adw.ResponseAppearance.SUGGESTED }, { _("Don't remind me again"), Adw.ResponseAppearance.DEFAULT } },
				false,
				(obj, res) => {
					if (app.question.end (res) == Tuba.Application.QuestionAnswer.NO) {
						settings.reply_to_old_post_reminder = false;
					}
					reply (btn);
				}
			);
		} else {
			reply (btn);
		}
	}

	private void on_bookmark_button_clicked (Gtk.Button btn) {
		var status_btn = btn as StatusActionButton;
		if (status_btn.working) return;

		status_btn.block_clicked ();
		status_btn.active = !status_btn.active;

		string action;
		Request req;
		if (status_btn.active) {
			action = "bookmark";
			req = this.status.bookmark_req ();
		} else {
			action = "unbookmark";
			req = this.status.unbookmark_req ();
		}

		debug (@"Performing status action '$action'…");
		mastodon_action (status_btn, req, action);
	}

	private void on_favorite_button_clicked (Gtk.Button btn) {
		var status_btn = btn as StatusActionButton;
		if (status_btn.working) return;

		status_btn.block_clicked ();
		status_btn.active = !status_btn.active;

		string action;
		Request req;
		if (status_btn.active) {
			action = "favorite";
			req = this.status.favourite_req ();
		} else {
			action = "unfavorite";
			req = this.status.unfavourite_req ();
		}
		status_btn.amount += status_btn.active ? 1 : -1;

		debug (@"Performing status action '$action'…");
		mastodon_action (status_btn, req, action, "favourites-count");
	}

	private void on_boost_button_clicked (Gtk.Button btn) {
		var status_btn = btn as StatusActionButton;
		if (status_btn.working) return;

		status_btn.block_clicked ();

		if (!status_btn.active && settings.advanced_boost_dialog) {
			Gtk.ListBox visibility_box = new Gtk.ListBox () {
				css_classes = {"content"},
				selection_mode = Gtk.SelectionMode.NONE
			};

			Gtk.CheckButton? group = null; // hashmap is not ordered
			Gee.HashMap<API.Status.ReblogVisibility, Gtk.CheckButton> check_buttons = new Gee.HashMap<API.Status.ReblogVisibility, Gtk.CheckButton> ();
			for (int i = 0; i < accounts.active.visibility_list.n_items; i++) {
				var visibility = (InstanceAccount.Visibility) accounts.active.visibility_list.get_item (i);
				var reblog_visibility = API.Status.ReblogVisibility.from_string (visibility.id);
				if (reblog_visibility == null) continue;

				var checkbutton = new Gtk.CheckButton () {
					css_classes = {"selection-mode"},
					active = settings.default_post_visibility == visibility.id
				};
				check_buttons.set (reblog_visibility, checkbutton);

				if (group != null) {
					checkbutton.group = group;
				} else {
					group = checkbutton;
				}

				var visibility_row = new Adw.ActionRow () {
					title = visibility.name,
					subtitle = visibility.description,
					activatable_widget = checkbutton
				};
				visibility_row.add_prefix (new Gtk.Image.from_icon_name (visibility.icon_name));
				visibility_row.add_prefix (checkbutton);

				visibility_box.append (visibility_row);
			}

			var dlg = new Adw.AlertDialog (
				_("Boost with Visibility"),
				null
			) {
				extra_child = visibility_box
			};
			dlg.add_responses (
				"no", _("Cancel"),
				"quote", _("Quote"),
				"yes", _("Boost")
			);
			dlg.set_response_appearance ("yes", Adw.ResponseAppearance.SUGGESTED);

			dlg.response.connect (res => {
				dlg.destroy ();

				switch (res) {
					case "yes":
					case "quote":
						API.Status.ReblogVisibility? reblog_visibility = null;
						check_buttons.foreach (e => {
							if (((Gtk.CheckButton) e.value).active) {
								reblog_visibility = (API.Status.ReblogVisibility) e.key;
								return false;
							}

							return true;
						});

						switch (res) {
							case "yes":
								commit_boost (status_btn, reblog_visibility);
								break;
							case "quote":
								bool supports_quotes = status.formal.can_be_quoted && accounts.active.instance_info.supports_quote_posting;
								new Dialogs.Compose (new API.Status.empty () {
									visibility = reblog_visibility == null ? settings.default_post_visibility : reblog_visibility.to_string (),
									content = supports_quotes ? "" : @"\n\nRE: $(status.formal.url ?? status.formal.account.url)"
								}, !supports_quotes, status.formal.id);
								status_btn.unblock_clicked ();
								break;
							default:
								assert_not_reached ();
						}
						break;
					default:
						status_btn.unblock_clicked ();
						break;
				}

				group = null;
				check_buttons.clear ();
			});

			dlg.present (app.main_window);
		} else {
			commit_boost (status_btn);
		}
	}

	private void commit_boost (StatusActionButton status_btn, API.Status.ReblogVisibility? visibility = null) {
			status_btn.active = !status_btn.active;

			string action;
			Request req;
			if (status_btn.active) {
				action = "reblog";
				req = this.status.reblog_req (visibility);
			} else {
				action = "unreblog";
				req = this.status.unreblog_req ();
			}

			status_btn.amount += status_btn.active ? 1 : -1;
			debug (@"Performing status action '$action'…");
			mastodon_action (status_btn, req, action, "reblogs-count");
	}

	private void mastodon_action (StatusActionButton status_btn, Request req, string action, string? count_property = null) {
		req.await.begin ((o, res) => {
			try {
				req.await.end (res);

				if (count_property != null) {
					int64 status_property_count;
					this.status.get (count_property, out status_property_count);
					this.status.set (count_property, status_property_count + (status_btn.active ? 1 : -1));
				}

				// Not reliable, it sometimes returns wrong info.
				// But it should be the desired one, as it updated the whole object.
				//
				//  var msg = req.await.end (res);

				//  var parser = Network.get_parser_from_inputstream (msg.response_body);
				//  var node = network.parse_node (parser);
				//  var e = Tuba.Helper.Entity.from_json (node, typeof (API.Status), true);

				//  if (count_property != null) {
				//  	int64 e_property_count;
				//  	int64 status_property_count;
				//  	((API.Status) e).get (count_property, out e_property_count);
				//  	this.status.get (count_property, out status_property_count);
				//  	if (e_property_count == status_property_count) {
				//  		((API.Status) e).set (count_property, e_property_count + (status_btn.active ? 1 : -1));
				//  	}
				//  }

				//  this.status.patch (e);
				debug (@"Status action '$action' complete");
			} catch (Error e) {
				warning (@"Couldn't perform action \"$action\" on a Status:");
				warning (e.message);
				app.toast ("%s: %s".printf (_("Network Error"), e.message));

				if (count_property != null)
					status_btn.amount += status_btn.active ? -1 : 1;
				status_btn.active = !status_btn.active;
			}

			status_btn.unblock_clicked ();
		});
	}
}
