[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/widgets/status.ui")]
#if USE_LISTVIEW
	public class Tuba.Widgets.Status : Adw.Bin {
#else
	public class Tuba.Widgets.Status : Gtk.ListBoxRow {
#endif

	API.Status? _bound_status = null;
	public API.Status? status {
		get { return _bound_status; }
		set {
			if (_bound_status != null)
				warning ("Trying to rebind a Status widget! This is not supposed to happen!");

			_bound_status = value;
			if (_bound_status != null) {
				bind ();
			}
			if (context_menu == null) {
				create_actions ();
			}
		}
	}

	public API.Account? kind_instigator { get; set; default = null; }
	private Gtk.Button? quoted_status_btn { get; set; default = null; }
	public API.Translation? translation { get; private set; default = null; }
	private Adw.Bin? emoji_reactions { get; set; default = null; }
	protected string? other_data { get; set; default = null; }

	private bool _enable_thread_lines = false;
	public bool enable_thread_lines {
		get { return _enable_thread_lines; }
		set {
			if (_enable_thread_lines != value) {
				_enable_thread_lines = value;
				update_collapse ();
			}
		}
	}

	private bool _can_be_opened = true;
	public bool can_be_opened {
		get {
			return _can_be_opened;
		}

		set {
			_can_be_opened = value;

			if (value) {
				this.add_css_class ("activatable");
			} else {
				this.remove_css_class ("activatable");
			}
		}
	}

	private bool _is_quote = false;
	public bool is_quote {
		get { return _is_quote; }
		set {
			_is_quote = value;

			Gtk.Widget?[] widgets_to_toggle = {
				menu_button,
				emoji_reactions,
				actions,
				quoted_status_btn,
				prev_card
			};

			foreach (var widget in widgets_to_toggle) {
				if (widget != null) {
					widget.visible = !value;
				}
			}
		}
	}

	string? _kind = null;
	public string? kind {
		get { return _kind; }
		set {
			if (value != _kind) {
				_kind = value;
				change_kind ();
				if (status != null)
					aria_describe_status ();
			}
		}
	}

	private bool _change_background_on_direct = true;
	public bool change_background_on_direct {
		get {
			return _change_background_on_direct;
		}
		set {
			_change_background_on_direct = value;
			if (!value) remove_css_class ("direct");
		}
	}

	public Dialogs.Composer.Dialog.SuccessCallback? reply_cb;

	[GtkChild] protected unowned Gtk.Box status_box;
	[GtkChild] protected unowned Gtk.Box avatar_side;
	[GtkChild] protected unowned Gtk.Box title_box;
	[GtkChild] protected unowned Gtk.Box content_side;
	[GtkChild] protected unowned Adw.WrapBox name_wrapbox;
	[GtkChild] public unowned Gtk.MenuButton menu_button;

	[GtkChild] protected unowned Gtk.Image header_icon;
	[GtkChild] protected unowned Widgets.RichLabel header_label;
	[GtkChild] protected unowned Gtk.Button header_button;

	[GtkChild] public unowned Widgets.Avatar avatar;
	[GtkChild] public unowned Gtk.Overlay avatar_overlay;
	[GtkChild] protected unowned Gtk.Button name_button;
	[GtkChild] protected unowned Widgets.RichLabel name_label;
	[GtkChild] protected unowned Gtk.Label handle_label;
	[GtkChild] public unowned Gtk.Box indicators;
	[GtkChild] public unowned Gtk.Label date_label;
	[GtkChild] protected unowned Gtk.Image pin_indicator;
	[GtkChild] protected unowned Gtk.Image edited_indicator;
	[GtkChild] protected unowned Gtk.Image visibility_indicator;

	// TODO: move to function
	[GtkChild] public unowned Gtk.Box content_column;
	[GtkChild] protected unowned Gtk.Stack spoiler_stack;
	[GtkChild] protected unowned Gtk.Box content_box;
	[GtkChild] public unowned Widgets.MarkupView content;
	[GtkChild] protected unowned Gtk.Button spoiler_button;
	[GtkChild] protected unowned Gtk.Label spoiler_label;
	[GtkChild] protected unowned Gtk.Label spoiler_label_rev;
	[GtkChild] protected unowned Gtk.Box spoiler_status_con;

	[GtkChild] protected unowned Widgets.FadeBin fade_bin;

	[GtkChild] public unowned Gtk.Stack filter_stack;
	[GtkChild] protected unowned Gtk.Label filter_label;

	public ActionsRow actions { get; private set; }
	protected Gtk.PopoverMenu context_menu { get; set; }
	private const GLib.ActionEntry[] ACTION_ENTRIES = {
		{"copy-url", copy_url},
		{"open-in-browser", open_in_browser},
		{"report", report_status}
	};
	private GLib.SimpleActionGroup action_group;
	private SimpleAction edit_history_simple_action;
	private SimpleAction stats_simple_action;
	private SimpleAction toggle_pinned_simple_action;
	private SimpleAction translate_simple_action;
	private SimpleAction show_original_simple_action;
	private SimpleAction? mute_conversation_action = null;
	private SimpleAction? unmute_conversation_action = null;

	void settings_updated () {
		Tuba.toggle_css (this, settings.larger_font_size, "ttl-status-font-large");
		Tuba.toggle_css (this, settings.larger_line_height, "ttl-status-line-height-large");
		Tuba.toggle_css (this, settings.scale_emoji_hover, "lww-scale-emoji-hover");
	}

	static construct {
		typeof (Widgets.Avatar).ensure ();
		typeof (Widgets.RichLabel).ensure ();
		typeof (Widgets.MarkupView).ensure ();
		typeof (Widgets.FadeBin).ensure ();
	}

	private void update_collapse () {
		fade_bin.reveal = !settings.collapse_long_posts || expanded || enable_thread_lines;
	}

	construct {
		pin_indicator.update_property (Gtk.AccessibleProperty.LABEL, pin_indicator.tooltip_text, -1);
		edited_indicator.update_property (Gtk.AccessibleProperty.LABEL, edited_indicator.tooltip_text, -1);

		name_label.use_markup = false;
		avatar_overlay.set_size_request (avatar.size, avatar.size);
		open.connect (on_open);
		if (settings.larger_font_size)
			add_css_class ("ttl-status-font-large");

		if (settings.larger_line_height)
			add_css_class ("ttl-status-line-height-large");

		if (settings.scale_emoji_hover)
			add_css_class ("lww-scale-emoji-hover");

		settings.notify["larger-font-size"].connect (settings_updated);
		settings.notify["larger-line-height"].connect (settings_updated);
		settings.notify["scale-emoji-hover"].connect (settings_updated);
		settings.notify["collapse-long-posts"].connect (update_collapse);

		edit_history_simple_action = new SimpleAction ("edit-history", null);
		edit_history_simple_action.activate.connect (view_edit_history);

		stats_simple_action = new SimpleAction ("status-stats", null);
		stats_simple_action.activate.connect (view_stats);

		action_group = new GLib.SimpleActionGroup ();
		action_group.add_action_entries (ACTION_ENTRIES, this);
		action_group.add_action (stats_simple_action);
		action_group.add_action (edit_history_simple_action);

		this.insert_action_group ("status", action_group);
		stats_simple_action.set_enabled (false);

		name_button.clicked.connect (on_name_button_clicked);

		update_collapse ();
	}

	private void on_name_button_clicked () {
		status.formal.account.open ();
	}

	private bool has_stats { get { return status.formal.reblogs_count != 0 || status.formal.favourites_count != 0; } }
	private void show_view_stats_action () {
		stats_simple_action.set_enabled (has_stats || has_reactions ());
	}

	private bool has_reactions () {
		bool res = false;

		var reactions = status.formal.compat_status_reactions;
		if (reactions != null && reactions.size > 0) {
			res = reactions[0].account_ids != null && reactions[0].account_ids.size > 0;
		}

		return res;
	}

	public Status (API.Status status) {
		Object (
			kind_instigator: status.account,
			status: status
		);

		if (kind == null) {
			if (status.reblog != null) {
				kind = InstanceAccount.KIND_REMOTE_REBLOG;
			} else if (status.in_reply_to_id != null || status.in_reply_to_account_id != null) {
				if (status.formal.in_reply_to_account_id != null && status.formal.mentions != null && status.formal.mentions.size > 0) {
					status.formal.mentions.@foreach (mention => {
						if (mention.id == status.formal.in_reply_to_account_id) {
							forced_kind_instigator_name = mention.acct;
							return false;
						}

						return true;
					});
				}

				kind = InstanceAccount.KIND_REPLY;
			}
		}

		init_menu_button ();
	}
	~Status () {
		debug ("Destroying Status widget");
		if (context_menu != null) {
			context_menu.menu_model = null;
			context_menu.dispose ();
		}
	}

	protected void init_menu_button () {
		if (context_menu == null) {
			create_actions ();
		}

		menu_button.popover = context_menu;
		menu_button.visible = true;
	}

	protected void create_actions () {
		create_context_menu ();

		mute_conversation_action = new SimpleAction ("mute-conversation", null);
		mute_conversation_action.activate.connect (toggle_mute_conversation);
		action_group.add_action (mute_conversation_action);

		unmute_conversation_action = new SimpleAction ("unmute-conversation", null);
		unmute_conversation_action.activate.connect (toggle_mute_conversation);
		action_group.add_action (unmute_conversation_action);

		if (status.formal.account.is_self ()) {
			if (status.formal.visibility != "direct") {
				toggle_pinned_simple_action = new SimpleAction ("toggle-pinned", null);
				toggle_pinned_simple_action.activate.connect (toggle_pinned);
				toggle_pinned_simple_action.set_enabled (false);
				action_group.add_action (toggle_pinned_simple_action);
			}

			var edit_status_simple_action = new SimpleAction ("edit-status", null);
			edit_status_simple_action.activate.connect (edit_status);
			action_group.add_action (edit_status_simple_action);

			var delete_status_simple_action = new SimpleAction ("delete-status", null);
			delete_status_simple_action.activate.connect (delete_status);
			action_group.add_action (delete_status_simple_action);
		} else if ((accounts.active.instance_info != null && accounts.active.instance_info.tuba_can_translate) || InstanceAccount.InstanceFeatures.TRANSLATION in accounts.active.tuba_instance_features) {
			translate_simple_action = new SimpleAction ("translate", null);
			translate_simple_action.activate.connect (translate);
			translate_simple_action.set_enabled (true);

			show_original_simple_action = new SimpleAction ("show-original", null);
			show_original_simple_action.activate.connect (translate);
			show_original_simple_action.set_enabled (false);

			action_group.add_action (translate_simple_action);
			action_group.add_action (show_original_simple_action);
		}

		update_mute_conversation_actions_enabled_status ();
	}

	private GLib.MenuItem pin_menu_item;
	protected void create_context_menu () {
		var menu_model = new GLib.Menu ();
		menu_model.append (_("Open in Browser"), "status.open-in-browser");
		menu_model.append (_("Copy URL"), "status.copy-url");

		// translators: as in post stats (who liked and boosted)
		var stats_menu_item = new MenuItem (_("View Stats"), "status.status-stats");
		stats_menu_item.set_attribute_value ("hidden-when", "action-disabled");
		menu_model.append_item (stats_menu_item);

		var edit_history_menu_item = new MenuItem (_("View Edit History"), "status.edit-history");
		edit_history_menu_item.set_attribute_value ("hidden-when", "action-disabled");
		menu_model.append_item (edit_history_menu_item);

		var mute_menu_item = new GLib.MenuItem (_("Mute"), "status.mute-conversation");
		mute_menu_item.set_attribute_value ("hidden-when", "action-disabled");

		var unmute_menu_item = new GLib.MenuItem (_("Unmute"), "status.unmute-conversation");
		unmute_menu_item.set_attribute_value ("hidden-when", "action-disabled");

		if (status.formal.account.is_self ()) {
			pin_menu_item = new GLib.MenuItem (_("Pin"), "status.toggle-pinned");
			update_toggle_pinned_label ();
			pin_menu_item.set_attribute_value ("hidden-when", "action-disabled");

			menu_model.append_item (pin_menu_item);
			menu_model.append_item (mute_menu_item);
			menu_model.append_item (unmute_menu_item);

			menu_model.append (_("Edit"), "status.edit-status");
			menu_model.append (_("Delete"), "status.delete-status");
		} else {
			menu_model.append_item (mute_menu_item);
			menu_model.append_item (unmute_menu_item);

			if (
				(
					(accounts.active.instance_info != null && accounts.active.instance_info.tuba_can_translate)
					|| InstanceAccount.InstanceFeatures.TRANSLATION in accounts.active.tuba_instance_features
				)
				&& status.formal.tuba_translatable
				&& (
					status.formal.visibility == "public"
					|| status.formal.visibility == "unlisted"
				)
				&& Tuba.default_locale != status.formal.language
				&& (
					Tuba.default_locale != "en-US"
					|| status.formal.language != "en"
				)
			) {
				var translate_menu_item = new GLib.MenuItem (_("Translate"), "status.translate");
				translate_menu_item.set_attribute_value ("hidden-when", "action-disabled");

				// translators: Post menu items to revert a translation
				var show_original_menu_item = new GLib.MenuItem (_("Show Original"), "status.show-original");
				show_original_menu_item.set_attribute_value ("hidden-when", "action-disabled");

				// We need 2 items because we apparently
				// can't update labels
				menu_model.append_item (translate_menu_item);
				menu_model.append_item (show_original_menu_item);
			}

			menu_model.append (_("Report"), "status.report");
		}

		context_menu = new Gtk.PopoverMenu.from_model (menu_model);
	}

	private void copy_url () {
		if (status.formal.url != null && settings.copy_private_link_reminder && (status.formal.visibility == "direct" || status.formal.visibility == "private")) {
			string body;
			if (status.formal.visibility == "direct") {
				// translators: dialog subtitle visibility warning when copying a link to a
				//				post that is private or mentioned-only
				body = _("Only mentioned people will be able to view it.");
			} else if (status.formal.account.is_self ()) {
				// translators: dialog subtitle visibility warning when copying a link to a
				//				post that is private or mentioned-only
				body = _("Only mentioned people and your followers will be able to view it.");
			} else {
				// translators: dialog subtitle visibility warning when copying a link to a post
				//				that is private or mentioned-only, the variable is a handle
				body = _("Only mentioned people and people that follow %s will be able to view it.").printf (status.formal.account.full_handle);
			}

			app.question.begin (
				// translators: the variable is the post visibility e.g. Public, Unlisted...
				{_("Copy %s Post Link?").printf (accounts.active.visibility[status.formal.visibility].name), false},
				{ body, false },
				app.main_window,
				{ { _("Copy"), Adw.ResponseAppearance.SUGGESTED }, { _("Don't remind me again"), Adw.ResponseAppearance.DEFAULT } },
				null,
				false,
				(obj, res) => {
					if (app.question.end (res) == Tuba.Application.QuestionAnswer.NO) {
						settings.copy_private_link_reminder = false;
					}

					Utils.Host.copy (status.formal.url);
					app.toast (_("Copied post url to clipboard"));
				}
			);
		} else {
			Utils.Host.copy (status.formal.url ?? status.formal.account.url);
			app.toast (_("Copied post url to clipboard"));
		}
	}

	private void open_in_browser () {
		string final_url = status.formal.url ?? status.formal.account.url;
		#if WEBKIT
			if (settings.use_in_app_browser_if_available && Views.Browser.can_handle_url (final_url)) {
				(new Views.Browser.with_url (final_url)).present (app.main_window);
				return;
			}
		#endif

		Utils.Host.open_url.begin (final_url);
	}

	private void report_status () {
		new Dialogs.Report (status.formal.account, status.formal.id, status.formal.mentions);
	}

	private void view_edit_history () {
		app.main_window.open_view (new Views.EditHistory (status.formal.id));
	}

	private void view_stats () {
		app.main_window.open_view (new Views.StatusStats (status.formal.id, has_reactions ()));
	}

	public void on_edit (API.Status x) {
		this.status.patch (x);
		bind ();
	}

	public signal void pin_changed ();
	private void toggle_pinned () {
		var p_action = status.formal.pinned ? "unpin" : "pin";
		new Request.POST (@"/api/v1/statuses/$(status.formal.id)/$p_action")
			.with_account (accounts.active)
			.then (() => {
				this.status.formal.pinned = p_action == "pin";
				pin_changed ();
			})
			.exec ();
	}

	private void edit_status () {
		edit_status_real ();
	}

	private void edit_status_real (bool redraft = false) {
		Request req;
		if (redraft) {
			req = this.status.formal.annihilate ();
		} else {
			req = new Request.GET (@"/api/v1/statuses/$(status.formal.id)/source");
		}

		req
			.with_account (accounts.active)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				var source = API.StatusSource.from (node);

				if (redraft) {
					new Dialogs.Composer.Dialog.edit (status.formal, source, null, true);
				} else {
					new Dialogs.Composer.Dialog.edit (status.formal, source, on_edit);
				}
			})
			.on_error ((code, message) => {
				if (redraft) {
					warning (@"Error while deleting status for redrafting: $code $message");
					app.toast (message, 0);
				} else {
					new Dialogs.Composer.Dialog.edit (status.formal, null, on_edit);
				}
			})

			.exec ();
	}

	private void delete_status () {
		var dlg = new Adw.AlertDialog (_("Delete Post?"), null) {
			heading_use_markup = false,
			body_use_markup = false,
			default_response = "delete",
			close_response = "cancel"
		};

		dlg.add_responses (
			"cancel", _("Cancel"),
			// translators: button on the delete post dialog that
			//				deletes the post and fills the composer
			//				with it so you can edit it
			"redraft", _("Redraft"),

			"delete", _("Delete")
		);
		dlg.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
		dlg.set_response_appearance ("redraft", Adw.ResponseAppearance.DESTRUCTIVE);
		dlg.choose.begin (app.main_window, null, (obj, res) => {
			switch (dlg.choose.end (res)) {
				case "delete":
					delete_status_real ();
					break;
				case "redraft":
					edit_status_real (true);
					break;
				default:
					break;
			}
		});
	}

	private void delete_status_real () {
		this.status.formal.annihilate ()
			//  .then ((in_stream) => {
			//  	var parser = Network.get_parser_from_inputstream (in_stream);
			//  	var root = network.parse (parser);
			//  	if (root.has_member ("error")) {
			//  		// TODO: Handle error (probably a toast?)
			//  	};
			//  })
			.exec ();
	}

	private void toggle_mute_conversation () {
		string api_action = status.formal.muted ? "unmute" : "mute";
		new Request.POST (@"/api/v1/statuses/$(status.formal.id)/$api_action")
			.with_account (accounts.active)
			.then (() => {
				status.formal.muted = !status.formal.muted;
				update_mute_conversation_actions_enabled_status ();
			})
			.on_error ((code, message) => {
				warning (@"Couldn't $api_action $(status.formal.id): $code $message");
				app.toast (
					api_action == "mute"
					// translators: toast shown when muting a post
					? _("Couldn't Mute Conversation: %s").printf (message)
					// translators: toast shown when unmuting a post
					: _("Couldn't Unmute Conversation: %s").printf (message)
				);
			})
			.exec ();
	}

	private void update_mute_conversation_actions_enabled_status () {
		if (mute_conversation_action == null || unmute_conversation_action == null) return;

		bool can_mute_convo = status.formal.account.is_self ();
		if (!can_mute_convo && status.formal.mentions != null && status.formal.mentions.size > 0) {
			foreach (var mention in status.formal.mentions) {
				if (mention.id == accounts.active.id) {
					can_mute_convo = true;
					break;
				}
			}
		}

		if (can_mute_convo) {
			mute_conversation_action.set_enabled (!status.formal.muted);
			unmute_conversation_action.set_enabled (status.formal.muted);
		} else {
			mute_conversation_action.set_enabled (false);
			unmute_conversation_action.set_enabled (false);
		}
	}

	private void translate () {
		if (translation != null) {
			translation = null;
			bind ();

			translate_simple_action.set_enabled (true);
			show_original_simple_action.set_enabled (false);
			return;
		}

		if (accounts.active.instance_info.pleroma != null) {
			new Request.GET (@"/api/v1/statuses/$(status.formal.id)/translations/$(Tuba.default_locale)")
				.with_account (accounts.active)
				.then ((in_stream) => {
					var parser = Network.get_parser_from_inputstream (in_stream);
					var node = network.parse_node (parser);
					var akkotrans = API.AkkomaTranslation.from (node);
					translation = new API.Translation () {
						content = akkotrans.text,
						detected_source_language = akkotrans.detected_language
					};
					bind ();

					translate_simple_action.set_enabled (false);
					show_original_simple_action.set_enabled (true);
				})
				.on_error ((code, message) => {
					warning (@"Couldn't translate $(status.formal.id): $code $message");
					app.toast (_("Couldn't translate: %s").printf (message));
				})
				.exec ();

			return;
		}

		new Request.POST (@"/api/v1/statuses/$(status.formal.id)/translate")
			.with_form_data ("lang", Tuba.default_locale)
			.with_account (accounts.active)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				translation = API.Translation.from (node);
				bind ();

				translate_simple_action.set_enabled (false);
				show_original_simple_action.set_enabled (true);
			})
			.on_error ((code, message) => {
				warning (@"Couldn't translate $(status.formal.id): $code $message");
				app.toast (_("Couldn't translate: %s").printf (message));
			})
			.exec ();
	}

	protected string spoiler_text {
		owned get {
			var text = status.formal.spoiler_text;
			if (text == null || text == "") {
				return _("Show More");
			} else {
				if (translation != null && translation.spoiler_text != null && translation.spoiler_text != "") {
					text = translation.spoiler_text;
				}

				spoiler_text_revealed = text;
				return text;
			}
		}
	}
	public string spoiler_text_revealed { get; set; default = _("Sensitive"); }

	// separator between the bottom bar items
	const string EXPANDED_SEPARATOR = " · ";
	protected string date {
		owned get {
			if (expanded) {
				// translators: this is a "long" date format shown in places like expanded posts or
				//				the profile "Joined" field. You can find all the available specifiers
				//				on https://valadoc.org/glib-2.0/GLib.DateTime.format.html
				//				Please do not stray far from the original and only include day, month
				//				and year.
				//				If unsure, either leave it as-is or set it to %x.
				var date_local = _("%B %e, %Y");

				// Re-parse the date into a MONTH DAY, YEAR (separator) HOUR:MINUTES
				var date_parsed = new GLib.DateTime.from_iso8601 (this.full_date, null);
				date_parsed = date_parsed.to_timezone (new TimeZone.local ());

				return date_parsed.format (@"$date_local $EXPANDED_SEPARATOR %H:%M").replace (" ", ""); // %e prefixes with whitespace on single digits
			} else {
				return Utils.DateTime.humanize (this.full_date);
			}
		}
	}

	protected string full_date {
		get {
			return status.formal.edited_at ?? status.formal.created_at;
		}
	}

	private string formatted_full_date () {
		return (new GLib.DateTime.from_iso8601 (this.full_date, null))
			.to_timezone (new TimeZone.local ())
			.format ("%F %T");
	}

	public string title_text {
		owned get {
			return status.formal.account.display_name;
		}
	}

	public string subtitle_text {
		owned get {
			return status.formal.account.handle;
		}
	}

	public string? avatar_url {
		owned get {
			return status.formal.account.avatar;
		}
	}

	public signal void open ();
	public virtual void on_open () {
		if (status.id == "")
			on_avatar_clicked ();
		else
			status.open ();
	}

	string? forced_kind_instigator_name;
	Widgets.Avatar? actor_avatar = null;
	ulong header_button_activate;
	private Binding actor_avatar_binding;
	string? header_kind_url = null;
	const string[] SHOULD_SHOW_ACTOR_AVATAR = {
		InstanceAccount.KIND_REBLOG,
		InstanceAccount.KIND_REMOTE_REBLOG,
		InstanceAccount.KIND_FAVOURITE
	};
	protected virtual void change_kind () {
		Tuba.InstanceAccount.Kind res_kind;

		string actor_name = this.kind_instigator.display_name;
		if (kind == InstanceAccount.KIND_REPLY) {
			actor_name = forced_kind_instigator_name;
		}

		accounts.active.describe_kind (
			this.kind,
			out res_kind,
			actor_name,
			this.kind_instigator.url,
			this.other_data
		);

		if (header_button_activate > 0) header_button.disconnect (header_button_activate);
		if (res_kind.icon == null) {
			//  status_box.margin_top = 18;
			header_icon.visible = header_button.visible = false;
			return;
		};

		header_icon.visible = header_button.visible = true;
		//  status_box.margin_top = 15;

		if (kind in SHOULD_SHOW_ACTOR_AVATAR) {
			if (actor_avatar == null) {
				actor_avatar = new Widgets.Avatar () {
					size = 34,
					valign = Gtk.Align.START,
					halign = Gtk.Align.START,
					overflow = Gtk.Overflow.HIDDEN,
					allow_mini_profile = true
				};
				actor_avatar.add_css_class ("ttl-status-avatar-actor");

				string actor_handle;
				if (this.kind_instigator != null) {
					actor_avatar_binding = this.bind_property ("kind_instigator", actor_avatar, "account", BindingFlags.SYNC_CREATE);
					actor_avatar.mini_clicked.connect (open_kind_instigator_account);
					actor_handle = this.kind_instigator.handle;
				} else {
					actor_avatar_binding = status.bind_property ("account", actor_avatar, "account", BindingFlags.SYNC_CREATE);
					actor_avatar.mini_clicked.connect (open_status_account);
					actor_handle = status.account.handle;
				}

				// translators: Tooltip text for avatars in posts.
				//				The variable is a string user handle.
				actor_avatar.tooltip_text = _("Open %s's Mini Profile").printf (actor_handle);
			}
			avatar.add_css_class ("ttl-status-avatar-border");
			avatar_overlay.child = actor_avatar;
		} else if (actor_avatar != null) {
			actor_avatar_binding.unbind ();

			avatar_overlay.child = null;
		}

		header_icon.icon_name = res_kind.icon;
		header_label.instance_emojis = this.kind_instigator.emojis_map;
		header_label.label = res_kind.description;
		header_kind_url = res_kind.url;

		if (header_kind_url != null) {
			header_button_activate = header_button.clicked.connect (on_header_button_clicked);
		} else {
			header_button_activate = header_button.clicked.connect (on_open);
		}
	}

	private void on_header_button_clicked () {
		if (header_kind_url == this.kind_instigator.url) {
			open_kind_instigator_account ();
		} else if (header_kind_url != null) {
			header_label.on_activate_link (header_kind_url);
		}
	}

	private void open_kind_instigator_account () {
		this.kind_instigator.open ();
	}

	private void open_status_account () {
		status.account.open ();
	}

	private void update_spoiler_status () {
		spoiler_status_con.visible = status.formal.tuba_spoiler_revealed && status.formal.has_spoiler;
		spoiler_stack.visible_child_name = status.formal.tuba_spoiler_revealed ? "content" : "spoiler";
	}

	private void update_spoiler_status_no_transition () {
		Gtk.StackTransitionType old_transition = spoiler_stack.transition_type;
		spoiler_stack.transition_type = NONE;
		update_spoiler_status ();
		spoiler_stack.transition_type = old_transition;
	}

	public void show_toggle_pinned_action () {
		if (toggle_pinned_simple_action != null)
			toggle_pinned_simple_action.set_enabled (true);
	}

	private void update_toggle_pinned_label () {
		if (pin_menu_item != null && status != null && status.formal != null)
			pin_menu_item.set_label (status.formal.pinned
				// translators: Unpin post from profile
				? _("Unpin")
				// translators: Pin post on profile
				: _("Pin")
			);
	}

	private void aria_describe_status () {
		if (settings.status_aria_verbosity < 1) return;

		if (filter_stack.visible_child_name == "filter") {
			// translators: This is an accessibility label.
			//				Screen reader users are going to hear this a lot,
			//				please be mindful.
			string aria_filter = _("Filtered post");
			if (this.status.formal.tuba_filter_warn != null) {
				aria_filter += @": $(this.status.formal.tuba_filter_warn)";
			}

			this.update_property (Gtk.AccessibleProperty.LABEL, aria_filter, -1);

			return;
		}

		// translators: This is an accessibility label.
		//				Screen reader users are going to hear this a lot,
		//				please be mindful.
		//				The first variable is the post's visibility (e.g. public).
		//				The second one is the author's name and the third
		//				one is the author's handle.
		string post = _("%s post by %s (%s).").printf (
			visibility_indicator.tooltip_text,
			this.title_text,
			this.subtitle_text
		);

		string aria_date = Utils.DateTime.humanize_aria (this.full_date);
		string aria_date_prefixed = status.formal.is_edited
			// translators: This is an accessibility label.
			//				Screen reader users are going to hear this a lot,
			//				please be mindful.
			//				The variable is a string date.
			? _("Edited: %s.").printf (aria_date)
			// translators: This is an accessibility label.
			//				Screen reader users are going to hear this a lot,
			//				please be mindful.
			//				The variable is a string date.
			: _("Published: %s.").printf (aria_date);

		string aria_pinned = "";
		if (settings.status_aria_verbosity >= 2 && status.formal.pinned) {
			// translators: This is an accessibility label.
			//				Screen reader users are going to hear this a lot,
			//				please be mindful.
			aria_pinned = _("The post is pinned.");
		}

		string aria_quote = "";
		if (settings.status_aria_verbosity >= 2 && status.formal.quote != null) {
			// translators: This is an accessibility label.
			//				Screen reader users are going to hear this a lot,
			//				please be mindful.
			aria_quote = _("Contains a quoted post.");
		}

		string aria_attachments = "";
		if (settings.status_aria_verbosity >= 3 && status.formal.has_media) {
			aria_attachments = GLib.ngettext (
				// translators: This is an accessibility label.
				//				Screen reader users are going to hear this a lot,
				//				please be mindful.
				//				The variable is the number of attachments the post has.
				"Contains %d attachment.", "Contains %d attachments.",
				(ulong) status.formal.media_attachments.size
			).printf (status.formal.media_attachments.size);
		}

		string aria_poll = "";
		if (settings.status_aria_verbosity >= 3 && status.formal.poll != null) {
			aria_poll = status.formal.poll.expired
				// translators: This is an accessibility label.
				//				Screen reader users are going to hear this a lot,
				//				please be mindful.
				? _("Contains an expired poll.")
				// translators: This is an accessibility label.
				//				Screen reader users are going to hear this a lot,
				//				please be mindful.
				: _("Contains a poll.");
		}

		string aria_spoiler = "";
		if (settings.status_aria_verbosity >= 2 && status.formal.has_spoiler) {
			if (status.formal.spoiler_text == null || status.formal.spoiler_text == "") {
				// translators: This is an accessibility label.
				//				Screen reader users are going to hear this a lot,
				//				please be mindful.
				aria_spoiler = _("The post has a spoiler.");
			} else {
				// translators: This is an accessibility label.
				//				Screen reader users are going to hear this a lot,
				//				please be mindful.
				//				The variable is the spoiler title.
				aria_spoiler = _("The post has the following spoiler: %s.").printf (this.spoiler_text);
			}
		}

		string aria_app = "";
		if (settings.status_aria_verbosity >= 3 && status.formal.application != null) {
			// translators: This is an accessibility label.
			//				Screen reader users are going to hear this a lot,
			//				please be mindful.
			//				The variable is the name of the app the post was
			//				made with (e.g. Tuba).
			aria_app = _("Posted using %s.").printf (status.formal.application.name);
		}

		string aria_reactions = "";
		if (settings.status_aria_verbosity >= 2 && status.formal.compat_status_reactions != null && status.formal.compat_status_reactions.size > 0) {
			aria_reactions = GLib.ngettext (
				// translators: This is an accessibility label.
				//				Screen reader users are going to hear this a lot,
				//				please be mindful.
				//				The variable is the amount of reactions the post
				//				has.
				"Contains %d reaction.", "Contains %d reactions.",
				(ulong) status.formal.compat_status_reactions.size
			).printf (status.formal.compat_status_reactions.size);
		}

		string aria_stats = "";
		if (settings.status_aria_verbosity >= 3) {
			// translators: This is an accessibility label.
			//				Screen reader users are going to hear this a lot,
			//				please be mindful.
			//				The variables are strings <amount> replies,
			//				<amount> boosts, <amount> favorites.
			aria_stats = "Post stats: %s, %s, %s.".printf (
				GLib.ngettext (
					"%s reply",
					"%s replies",
					(ulong) status.formal.replies_count
				).printf (status.formal.replies_count.to_string ()),
				GLib.ngettext (
					"%s boost",
					"%s boosts",
					(ulong) status.formal.reblogs_count
				).printf (status.formal.reblogs_count.to_string ()),
				GLib.ngettext (
					"%s favorite",
					"%s favorites",
					(ulong) status.formal.favourites_count
				).printf (status.formal.favourites_count.to_string ())
			);
		}

		string aria_translation = "";
		if (settings.status_aria_verbosity >= 3 && translation_label != null) aria_translation = translation_label.get_text ();

		this.update_property (
			Gtk.AccessibleProperty.LABEL,
			"%s %s %s %s %s %s %s %s %s %s %s %s.".printf (
				header_label.accessible_text,
				post,
				aria_date_prefixed,
				aria_pinned,
				aria_quote,
				aria_attachments,
				aria_poll,
				aria_spoiler,
				aria_stats,
				aria_reactions,
				aria_app,
				aria_translation
			),
			-1
		);

		spoiler_status_con.update_property (Gtk.AccessibleProperty.LABEL, aria_spoiler, -1);

		if (quoted_status_btn != null) {
			// translators: This is an accessibility label.
			//				Screen reader users are going to hear this a lot,
			//				please be mindful.
			//				This is used to announce the quoted post
			quoted_status_btn.update_property (Gtk.AccessibleProperty.DESCRIPTION, _("Quoted Post"), -1);
		}
	}

	private Widgets.HashtagBar hashtag_bar;
	protected Widgets.PreviewCard prev_card;
	private Widgets.Attachment.Box attachments;
	private Gtk.Label translation_label;
	public Widgets.VoteBox poll;
	private Gtk.Image? local_only_indicator = null;
	const string[] ALLOWED_CARD_TYPES = { "link", "video" };
	ulong[] formal_handler_ids = {};
	ulong[] this_handler_ids = {};
	Binding[] bindings = {};
	protected virtual void bind () {
		soft_unbind ();

		if (this.status.formal.filtered != null && this.status.formal.filtered.size > 0) {
			filter_stack.visible_child_name = "filter";

			string? filter_warn = this.status.formal.tuba_filter_warn;
			if (filter_warn != null) {
				filter_label.label = _("Filtered: %s").printf (filter_warn);
			} else {
				filter_label.label = _("Filtered");
			}
		}

		if (actions != null) {
			actions.unbind ();
			content_column.remove (actions);
		}
		actions = new ActionsRow (this.status.formal);
		actions.reply.connect (on_reply_button_clicked);
		content_column.append (actions);

		this.content.bold_text_regex = status.tuba_search_query_regex;
		this.content.has_quote = status.formal.quote != null && status.formal.quote.tuba_has_quote;
		this.content.mentions = status.formal.mentions;
		this.content.instance_emojis = status.formal.emojis_map;

		if (translation != null && translation.content != null && translation.content != "") {
			this.content.content = translation.content;
		} else {
			this.content.content = status.formal.content;
		}

		if (quoted_status_btn != null) content_box.remove (quoted_status_btn);
		if (this.content.has_quote && !is_quote) {
			var quoted_status = (Widgets.Status) status.formal.quote.to_widget ();
			quoted_status.is_quote = true;
			quoted_status.add_css_class ("frame");
			quoted_status.add_css_class ("ttl-quote");

			quoted_status_btn = new Gtk.Button () {
				child = quoted_status,
				css_classes = { "ttl-flat-button", "flat" }
			};
			quoted_status_btn.clicked.connect (quoted_status.on_open);
			content_box.append (quoted_status_btn);
		}

		if (emoji_reactions != null) content_column.remove (emoji_reactions);
		if (status.formal.compat_status_reactions != null) {
			emoji_reactions = new ReactionsRow (status.formal.id, status.formal.compat_status_reactions);
			content_column.insert_child_after (emoji_reactions, spoiler_stack);
		}

		spoiler_label.label = this.spoiler_text;
		spoiler_label_rev.label = this.spoiler_text_revealed;

		status.formal.tuba_spoiler_revealed = !status.formal.has_spoiler || status.formal.tuba_spoiler_revealed;
		update_spoiler_status_no_transition ();

		handle_label.label = handle_label.tooltip_text = this.subtitle_text;
		date_label.label = this.date;

		if (!expanded) {
			date_label.tooltip_text = formatted_full_date ();
			date_label.update_property (Gtk.AccessibleProperty.LABEL, date_label.tooltip_text, -1);
		}

		pin_indicator.visible = status.formal.pinned;
		update_toggle_pinned_label ();
		edited_indicator.visible = status.formal.is_edited;
		edit_history_simple_action.set_enabled (status.formal.is_edited);

		if (accounts.active.visibility.has_key (status.formal.visibility)) {
			visibility_indicator.visible = true;
			var t_visibility = accounts.active.visibility[status.formal.visibility];
			visibility_indicator.icon_name = t_visibility.small_icon_name;
			visibility_indicator.tooltip_text = t_visibility.name;
			visibility_indicator.update_property (Gtk.AccessibleProperty.LABEL, t_visibility.name, -1);
		} else {
			visibility_indicator.visible = false;
		}

		if (change_background_on_direct && status.formal.visibility == "direct") {
			this.add_css_class ("direct");
		} else {
			this.remove_css_class ("direct");
		}

		if (local_only_indicator != null) indicators.remove (local_only_indicator);
		if (status.formal.compat_local_only) {
			this.add_css_class ("local");

			if (local_only_indicator == null) local_only_indicator = new Gtk.Image.from_icon_name ("tuba-important-small-symbolic") {
				css_classes = {"dim-label"},
				tooltip_text = _("Local Only")
			};
			indicators.prepend (local_only_indicator);
		} else {
			this.remove_css_class ("local");
		}

		avatar.account = status.formal.account;
		// translators: Tooltip text for avatars in posts.
		//				The variable is a string user handle.
		name_button.tooltip_text = avatar.tooltip_text = _("Open %s's Profile").printf (status.formal.account.handle);

		name_label.instance_emojis = status.formal.account.emojis_map;
		name_label.label = title_text;

		if (poll != null) content_box.remove (poll);
		if (status.formal.poll != null) {
			poll = new Widgets.VoteBox ();
			poll.translation = translation;
			bindings += status.formal.bind_property ("poll", poll, "poll", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
			content_box.append (poll);
		}

		if (attachments != null) content_box.remove (attachments);
		if (status.formal.has_media) {
			if (translation != null && translation.media_attachments != null && translation.media_attachments.size > 0) {
				var translated_media = new Gee.HashMap<string, string> ();
				translation.media_attachments.@foreach (e => {
					translated_media.set (e.id, e.description);
					return true;
				});

				status.formal.media_attachments.@foreach (item => {
					if (translated_media.has_key (item.id)) {
						item.tuba_translated_alt_text = translated_media.get (item.id);
					}

					return true;
				});
			} else {
				status.formal.media_attachments.@foreach (item => {
					item.tuba_translated_alt_text = null;
					return true;
				});
			}

			attachments = new Widgets.Attachment.Box ();
			attachments.has_spoiler = status.formal.sensitive;
			attachments.list = status.formal.media_attachments;

			#if GSTREAMER
				if (attachments != null && attachments.has_thumbnailess_audio) {
					bindings += avatar.bind_property ("custom-image", attachments, "audio-fallback-paintable", BindingFlags.SYNC_CREATE);
				}
			#endif

			content_box.append (attachments);
		}

		if (translation_label != null) content_box.remove (translation_label);
		if (translation != null && translation.provider != "") {
			string translation_label_content;
			if (translation.detected_source_language != "") {
				// translatiors: the first variable is a language name,
				// 				 the second variable is a service name e.g. DeepL
				translation_label_content = _("Translated from %s using %s").printf (translation.detected_source_language.up (), translation.provider);
			} else {
				// translatiors: the variable is a service name e.g. DeepL
				translation_label_content = _("Translated using %s").printf (translation.provider);
			}

			translation_label = new Gtk.Label (translation_label_content) {
				wrap = true,
				wrap_mode = Pango.WrapMode.WORD_CHAR,
				xalign = 1.0f,
				css_classes = {"subtitle"}
			};
			content_box.append (translation_label);
		}

		if (prev_card != null) content_box.remove (prev_card);
		if (settings.show_preview_cards && !status.formal.has_media && quoted_status_btn == null && status.formal.card != null && status.formal.card.kind in ALLOWED_CARD_TYPES) {
			prev_card = (Widgets.PreviewCard) status.formal.card.to_widget ();
			prev_card.button.clicked.connect (open_card_url);
			content_box.append (prev_card);
		}

		if (hashtag_bar != null) content_box.remove (hashtag_bar);
		if (this.content.get_extracted_tags () != null && this.content.get_extracted_tags ().length > 0) {
			hashtag_bar = new Widgets.HashtagBar (this.content.get_extracted_tags ());
			content_box.append (hashtag_bar);
		}

		show_view_stats_action ();
		formal_handler_ids += status.formal.notify["reblogs-count"].connect (show_view_stats_action);
		formal_handler_ids += status.formal.notify["favourites-count"].connect (show_view_stats_action);
		formal_handler_ids += status.formal.notify["tuba-thread-role"].connect (install_thread_line);
		formal_handler_ids += status.formal.notify["tuba-spoiler-revealed"].connect (update_spoiler_status);

		aria_describe_status ();
		update_mute_conversation_actions_enabled_status ();
	}

	public void soft_unbind () {
		filter_stack.visible_child_name = "status";

		foreach (var handler_id in formal_handler_ids) {
			status.formal.disconnect (handler_id);
		}
		formal_handler_ids = {};

		foreach (var handler_id in this_handler_ids) {
			this.disconnect (handler_id);
		}
		this_handler_ids = {};

		foreach (var binding in bindings) {
			binding.unbind ();
		}
		bindings = {};
	}

	void open_card_url () {
		status.formal.card.open_special_card ();
	}

	private void on_reply (API.Status x) {
		if (reply_cb != null)
			reply_cb (x);
	}

	private void on_reply_button_clicked () {
		new Dialogs.Composer.Dialog.reply (status.formal, on_reply);
	}

	[GtkCallback] public void on_fade_reveal () {
		fade_bin.reveal_animated ();
	}

	[GtkCallback] public void toggle_spoiler () {
		status.formal.tuba_spoiler_revealed = !status.formal.tuba_spoiler_revealed;
		if (status.formal.tuba_spoiler_revealed) {
			content.grab_focus ();
		} else {
			spoiler_button.grab_focus ();
		}
	}

	[GtkCallback] public void toggle_filter () {
		if (this.status.formal.filtered != null && this.status.formal.filtered.size > 0) {
			filter_stack.visible_child_name = filter_stack.visible_child_name == "filter" ? "status" : "filter";
			aria_describe_status ();
		}
	}

	[GtkCallback] public void on_avatar_clicked () {
		status.formal.account.open ();
	}

	public void to_display_only () {
		if (poll != null) {
			poll.usable = false;
			poll.can_target = false;
			poll.focusable = false;
			poll.can_focus = false;
		}
		if (hashtag_bar != null) hashtag_bar.to_display_only ();
		if (attachments != null) attachments.usable = false;
		if (emoji_reactions != null) emoji_reactions.visible = false;
		this.can_be_opened = false;
		this.actions.visible = false;
		this.menu_button.visible = false;
		this.activatable = false;
		this.avatar.allow_mini_profile = false;
		this.avatar.can_target = false;
		this.avatar.focusable = false;
		this.avatar.can_focus = false;
		name_button.can_target = false;
		name_button.can_focus = false;
		name_button.focusable = false;
		this.content.selectable = true;
		this.content.can_open = false;
		this.avatar.accessible_role = Gtk.AccessibleRole.PRESENTATION;
		this.date_label.accessible_role = Gtk.AccessibleRole.PRESENTATION;
		name_button.accessible_role = Gtk.AccessibleRole.PRESENTATION;
		//  this.fade_bin.reveal = true;
		this.reset_relation (DESCRIBED_BY);
		this.reset_property (LABEL);
		this.reset_property (DESCRIPTION);
	}

	bool expanded = false;
	public void expand_root () {
		if (expanded) return;

		expanded = true;
		content.selectable = true;
		content.add_css_class ("ttl-large-body");

		// Move the avatar & thread line into the name box
		status_box.remove (avatar_side);
		title_box.prepend (avatar_side);
		title_box.spacing = 14;

		// Make the name box take 2 rows
		name_wrapbox.child_spacing = 600;
		content_side.spacing = 10;

		// Remove the date & indicators
		indicators.remove (date_label);
		if (status.formal.is_edited)
			indicators.remove (edited_indicator);
		indicators.remove (visibility_indicator);
		if (local_only_indicator != null) local_only_indicator.visible = false;

		date_label.label = this.date;
		date_label.wrap = true;
		date_label.tooltip_text = null;

		// The bottom bar
		var bottom_info = new Adw.WrapBox () {
			margin_top = 6
		};

		// Insert it after the post content
		content_column.insert_child_after (bottom_info, spoiler_stack);
		bottom_info.append (date_label);
		if (status.formal.is_edited)
			append_to_bottom_bar (bottom_info, edited_indicator);
		append_to_bottom_bar (bottom_info, visibility_indicator);

		edited_indicator.valign = Gtk.Align.CENTER;
		visibility_indicator.valign = Gtk.Align.CENTER;

		// If the application used to make the post is available
		if (status.formal.application != null) {
			var has_link = status.formal.application.website != null;
			// Make it an anchor if it has a website
			var application_link = has_link
				? @"<a href=\"$(status.formal.application.website)\">$(status.formal.application.name)</a>"
				: status.formal.application.name;
			var application_label = new Gtk.Label (application_link) {
				wrap = true,
				use_markup = has_link,
				halign = Gtk.Align.START,
				css_classes = { "body" }
			};

			// If it's not an anchor, it should follow the styling of the other items
			if (!has_link) application_label.add_css_class ("dim-label");

			append_to_bottom_bar (bottom_info, application_label);
		}
	}

	private void append_to_bottom_bar (Adw.WrapBox wrap_box, Gtk.Widget child, string separator = EXPANDED_SEPARATOR) {
		wrap_box.append (new Gtk.Label (separator) { css_classes = {"dim-label"}, halign = Gtk.Align.START });
		wrap_box.append (child);
	}

	const float THREAD_WIDTH = 4f;

	public override void snapshot (Gtk.Snapshot snapshot) {
		if (!expanded && enable_thread_lines && status.formal.tuba_thread_role != NONE && filter_stack.visible_child_name == "status") {
			float y;
			float height;

			// Get the avatar's position
			Graphene.Point avatar_point;
			avatar.compute_point (
				this,
				Graphene.Point () { x = 0.0f, y=0.0f },
				out avatar_point
			);

			// NOTE: we need the thread line to be > status height as
			//		 it looks better if it reaches the status' bounds
			//       so the sizes below are either always bigger or
			//		 start at a negative point
			switch (status.formal.tuba_thread_role) {
				// Thread starter line needs to start from the
				// center of the avatar and end at the end of
				// the status
				case START:
					y = avatar_point.y + avatar.get_height () / 2f;
					height = (float) this.get_height ();
					break;
				// Thread in-between line needs to start from the
				// top and end at the end of the status
				case MIDDLE:
					y = -4f;
					height = this.get_height () * 1.2f;
					break;
				// Thread end line needs to start from the
				// status top and end at the center of the
				// avatar
				case END:
					y = -4f;
					height = (avatar_point.y + avatar.get_height () / 2f) + 4f;
					break;
				default:
					assert_not_reached ();
			}

			var line_rect = Graphene.Rect () {
				// we need the center of the avatar for the x point minus half the thread line width
				origin = Graphene.Point () { x = avatar_point.x + avatar.get_width () / 2f - THREAD_WIDTH / 2f, y = y },
				size = Graphene.Size () { width = THREAD_WIDTH, height = height }
			};

			snapshot.push_opacity (0.1);
			snapshot.append_color (this.get_color (), line_rect);
			snapshot.pop ();
		}

		base.snapshot (snapshot);
	}

	// Threads
	public void install_thread_line () {
		this.queue_draw ();
	}
}
