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
	public void bind () {
		if (bindings.length != 0) return;

		bindings += this.status.bind_property ("replies-count", reply_button, "amount", GLib.BindingFlags.SYNC_CREATE);
		bindings += this.status.bind_property ("in-reply-to-id", reply_button, "default_icon_name", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string (src.get_string () != null ? "tuba-reply-all-symbolic" : "tuba-reply-sender-symbolic");
			return true;
		});

		bindings += this.status.bind_property ("can-be-boosted", reblog_button, "sensitive", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			bool src_val = src.get_boolean ();
			target.set_boolean (src_val);

			if (src_val) {
				reblog_button.tooltip_text = _("Boost");
				reblog_button.default_icon_name = "tuba-media-playlist-repeat-symbolic";
			} else {
				reblog_button.tooltip_text = _("This post can't be boosted");
				reblog_button.default_icon_name = accounts.active.visibility[this.status.visibility].icon_name;
			}

			return true;
		});
		bindings += this.status.bind_property ("reblogged", reblog_button, "active", GLib.BindingFlags.SYNC_CREATE);
		bindings += this.status.bind_property ("reblogs-count", reblog_button, "amount", GLib.BindingFlags.SYNC_CREATE);

		bindings += this.status.bind_property ("favourited", favorite_button, "active", GLib.BindingFlags.SYNC_CREATE);
		bindings += this.status.bind_property ("favourites-count", favorite_button, "amount", GLib.BindingFlags.SYNC_CREATE);

		bindings += this.status.bind_property ("bookmarked", bookmark_button, "active", GLib.BindingFlags.SYNC_CREATE);
	}

	public void unbind () {
		foreach (var binding in bindings) {
			binding.unbind ();
		}

		bindings = {};
	}

    construct {
        this.add_css_class ("ttl-post-actions");
        this.spacing = 6;

		reply_button = new StatusActionButton.with_icon_name ("tuba-reply-sender-symbolic") {
			active = false,
			css_classes = { "ttl-status-action-reply", "flat", "circular" },
			halign = Gtk.Align.START,
			hexpand = true,
			tooltip_text = _("Reply")
		};
		reply_button.clicked.connect (on_reply_button_clicked);
		this.append (reply_button);

		reblog_button = new StatusActionButton.with_icon_name ("tuba-media-playlist-repeat-symbolic") {
			css_classes = { "ttl-status-action-reblog", "flat", "circular" },
			halign = Gtk.Align.START,
			hexpand = true,
			tooltip_text = _("Boost")
		};
		reblog_button.clicked.connect (on_boost_button_clicked);
		this.append (reblog_button);

		favorite_button = new StatusActionButton.with_icon_name ("tuba-unstarred-symbolic") {
			active_icon_name = "tuba-starred-symbolic",
			css_classes = { "ttl-status-action-star", "flat", "circular" },
			halign = Gtk.Align.START,
			hexpand = true,
			tooltip_text = _("Favorite")
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
		reply (btn);
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

		message (@"Performing status action '$action'…");
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

		message (@"Performing status action '$action'…");
		mastodon_action (status_btn, req, action, "favourites-count");
	}

	private void on_boost_button_clicked (Gtk.Button btn) {
		var status_btn = btn as StatusActionButton;
		if (status_btn.working) return;

		status_btn.block_clicked ();
		status_btn.active = !status_btn.active;

		string action;
		Request req;
		if (status_btn.active) {
			action = "reblog";
			req = this.status.reblog_req ();
		} else {
			action = "unreblog";
			req = this.status.unreblog_req ();
		}
		status_btn.amount += status_btn.active ? 1 : -1;

		message (@"Performing status action '$action'…");
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
				//  var e = entity_cache.lookup_or_insert (node, typeof (API.Status), true);

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
				message (@"Status action '$action' complete");
			} catch (Error e) {
				warning (@"Couldn't perform action \"$action\" on a Status:");
				warning (e.message);

				var dlg = app.inform (_("Network Error"), e.message);
				dlg.present ();

				if (count_property != null)
					status_btn.amount += status_btn.active ? -1 : 1;
				status_btn.active = !status_btn.active;
			}

			status_btn.unblock_clicked ();
		});
	}
}
