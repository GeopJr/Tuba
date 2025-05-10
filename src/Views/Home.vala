public class Tuba.Views.Home : Views.Timeline {
	public class SuggestionObject : Object, Widgetizable {
		public override Gtk.Widget to_widget () {
			return new Widgets.AccountSuggestions ();
		}
	}

	Gtk.Revealer compose_button_rev;
	Gtk.Button compose_button;
	construct {
		url = "/api/v1/timelines/home";
		label = _("Home");
		icon = "user-home-symbolic";
		badge_number = 0;
		needs_attention = false;

		scroll_to_top_rev.margin_end = 32;
		scroll_to_top_rev.margin_bottom = 24;
		scroll_to_top_rev.add_css_class ("scroll-to-top-btn");

		compose_button = new Gtk.Button.from_icon_name ("document-edit-symbolic") {
			action_name = "app.compose",
			tooltip_text = _("Compose"),
			css_classes = { "circular", "compose-button", "suggested-action" }
		};
		compose_button_rev = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
			valign = halign = Gtk.Align.END,
			margin_end = 24,
			margin_bottom = 24,
			reveal_child = true,
			overflow = Gtk.Overflow.VISIBLE,
			child = compose_button
		};

		compose_button_rev.notify["reveal-child"].connect (toggle_scroll_to_top_margin);
		compose_button_rev.notify["child-revealed"].connect (on_child_revealed);
		toggle_scroll_to_top_margin ();

		scrolled_overlay.add_overlay (compose_button_rev);

		#if DEV_MODE
			app.dev_new_post.connect (node => {
				try {
					model.insert (0, Entity.from_json (accepts, node));
				} catch (Error e) {
					warning (@"Error getting Entity from json: $(e.message)");
				}
			});
		#endif

		app.notify["is-mobile"].connect (() => {
			if (!app.is_mobile)
				set_compose_button_reveal_child (true);
		});

		this.bind_property ("entity-queue-size", this, "badge-number", BindingFlags.SYNC_CREATE);
		this.bind_property ("badge-number", Tuba.Mastodon.Account.PLACE_HOME, "badge", BindingFlags.SYNC_CREATE
			#if DEV_MODE
				| BindingFlags.BIDIRECTIONAL
			#endif
		);

		app.remove_user_id.connect (on_remove_user);
	}

	void toggle_scroll_to_top_margin () {
		Tuba.toggle_css (scroll_to_top_rev, compose_button_rev.reveal_child, "composer-btn-revealed");
	}

	void set_compose_button_reveal_child (bool reveal) {
		if (compose_button_rev.reveal_child == reveal) return;

		compose_button.margin_bottom = 24;
		compose_button_rev.margin_bottom = 0;

		compose_button_rev.reveal_child = reveal;
	}

	void on_child_revealed () {
		compose_button.margin_bottom = 0;
		compose_button_rev.margin_bottom = 24;
	}

	bool has_account_suggestions = false;
	public override void on_content_changed () {
		base.on_content_changed ();
		if (
			settings.account_suggestions
			&& !has_account_suggestions
			&& !this.empty
			&& accounts.active.following_count <= 10
		) {
			has_account_suggestions = true;
			model.append (new SuggestionObject ());
		}
	}

	public override void on_refresh () {
		has_account_suggestions = false;
		base.on_refresh ();
	}

	double last_adjustment = 0;
	double show_on_adjustment = -1;
	bool last_direction_down = false;
	protected override void on_scrolled_vadjustment_value_change () {
		base.on_scrolled_vadjustment_value_change ();
		if (app.is_mobile != true) return;

		double trunced = Math.trunc (scrolled.vadjustment.value);
		bool direction_down = trunced == last_adjustment ? last_direction_down : trunced > last_adjustment;
		last_direction_down = direction_down;

		if (!direction_down && show_on_adjustment == -1) {
			show_on_adjustment = last_adjustment - 200;
			if (show_on_adjustment <= 0) show_on_adjustment = last_adjustment;
		} else if (direction_down) {
			show_on_adjustment = -1;
		}

		if (compose_button_rev.reveal_child && direction_down)
			set_compose_button_reveal_child (false);
		else if (!compose_button_rev.reveal_child && !direction_down && trunced <= show_on_adjustment)
			set_compose_button_reveal_child (true);

		last_adjustment = trunced;
	}

	public override string? get_stream_url () {
		return account != null
			? @"$(account.instance)/api/v1/streaming?stream=user&access_token=$(account.access_token)"
			: null;
	}
}
