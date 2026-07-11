public class Tuba.Views.Hashtag : Views.Timeline {
	public bool featured { get; private set; default = false; }
	private string tag { get; set; }

	private bool _following = false;
	private bool following {
		get { return _following; }
		set {
			_following = value;
			update_follow_button ();
		}
	}

	public Hashtag (string tag, bool? following = null, string? url_basename = null, bool? featured = null) {
		string temp_tag = url_basename == null ? tag : url_basename;
		Object (
			url: @"/api/v1/timelines/tag/$temp_tag",
			label: @"#$tag"
		);

		this.tag = temp_tag;
		if (following != null) {
			this.following = following;
		} else {
			init_tag.begin ();
		}

		if (featured != null) {
			this.featured = featured;
			create_featuring_button ();
		} else if (following != null) {
			init_tag.begin ();
		}
	}

	Widgets.StatusActionButton? feature_tag_btn = null;
	private void create_featuring_button () {
		if ((accounts.active.tuba_api_versions.mastodon <= 5 && !(InstanceAccount.InstanceFeatures.FEATURE_TAGS in accounts.active.tuba_instance_features)) || feature_tag_btn != null) return;

		feature_tag_btn = new Widgets.StatusActionButton.with_icon_name ("tuba-heart-outline-thick-symbolic") {
			active_icon_name = "tuba-heart-filled-symbolic",
			css_classes = { "ttl-status-action-heart", "raised" },
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			// translators: label on headerbar button on hashtag views that 'features'
			//				the hashtag on the user's profile
			tooltip_text = _("Feature on Profile"),
		};
		this.bind_property ("featured", feature_tag_btn, "active", SYNC_CREATE);
		feature_tag_btn.clicked.connect (on_feature);

		header.pack_start (feature_tag_btn);
	}

	private void on_feature () {
		feature_tag_btn.block_clicked ();
		this.featured = !this.featured;
		on_feature_real.begin ();
	}

	private async void on_feature_real () {
		var req = new RequestV2 (@"/api/v1/tags/$tag/$(!this.featured ? "unfeature" : "feature")", POST) { // we reversed it above
			account = accounts.active,
			ctx = this
		};

		try {
			var in_stream = yield req.exec (null);
			Json.Parser parser = yield Network.get_parser_from_inputstream_async (in_stream);
			var node = network.parse_node (parser);
			var tag_info = API.Tag.from (node);

			if (this.following != tag_info.following) this.following = tag_info.following;
			if (this.featured != tag_info.featuring) this.featured = tag_info.featuring;

			app.refresh_featured ();
			feature_tag_btn.unblock_clicked ();
		} catch (Error e) {
			warning (@"Couldn't feature tag '$tag': $(e.code) $(e.message)");
			app.toast (e.message);
			this.featured = !this.featured;
			feature_tag_btn.unblock_clicked ();
		}
	}

	Gtk.Button? follow_tag_btn = null;
	private void create_follow_button () {
		if (follow_tag_btn != null) return;

		follow_tag_btn = new Gtk.Button.with_label (_("Follow"));
		follow_tag_btn.clicked.connect (follow);

		header.pack_end (follow_tag_btn);
	}

	private void update_follow_button () {
		if (follow_tag_btn == null) create_follow_button ();
		if (this.following) {
			follow_tag_btn.label = _("Unfollow");
			follow_tag_btn.remove_css_class ("suggested-action");
			follow_tag_btn.add_css_class ("destructive-action");
		} else {
			follow_tag_btn.label = _("Follow");
			follow_tag_btn.remove_css_class ("destructive-action");
			follow_tag_btn.add_css_class ("suggested-action");
		}
	}

	private void follow () {
		var action = this.following ? "unfollow" : "follow";
		this.following = !this.following;

		follow_real.begin (action);
	}

	private async void follow_real (string action) {
		var req = new RequestV2 (@"/api/v1/tags/$tag/$action", POST) {
			account = accounts.active,
			ctx = this
		};

		try {
			var in_stream = yield req.exec (null);
			Json.Parser parser = yield Network.get_parser_from_inputstream_async (in_stream);
			var root = network.parse (parser);
			if (!root.has_member ("following")) {
				this.following = !this.following;
			} else if (!this.following) {
				remove_from_favs ();
			}
		} catch {}
	}

	private void remove_from_favs () {
		if (settings.favorite_tags_ids.length == 0) return;

		string[] new_ids = {};
		string down_name = this.tag.down ();
		foreach (string tag_name in settings.favorite_tags_ids) {
			if (down_name != tag_name.down ()) new_ids += tag_name;
		}

		if (settings.favorite_tags_ids.length != new_ids.length) {
			settings.favorite_tags_ids = new_ids;
			GLib.Idle.add (accounts.active.gather_fav_tags);
		}
	}

	private async void init_tag () {
		var req = new RequestV2 (@"/api/v1/tags/$tag") {
			account = accounts.active,
			ctx = this
		};

		try {
			var in_stream = yield req.exec (null);
			Json.Parser parser = yield Network.get_parser_from_inputstream_async (in_stream);
			var node = network.parse_node (parser);
			var tag_info = API.Tag.from (node);

			this.following = tag_info.following;
			this.featured = tag_info.featuring;
			create_featuring_button ();
		} catch {}
	}

	public override string? get_stream_url () {
		var split_url = url.split ("/");
		var tag = split_url[split_url.length - 1];
		return account != null
			? @"$(account.tuba_streaming_url)/api/v1/streaming?stream=hashtag&tag=$tag&access_token=$(account.access_token)"
			: null;
	}

}
