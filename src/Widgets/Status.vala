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
	public bool enable_thread_lines { get; set; default = false; }

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

	public Dialogs.Compose.SuccessCallback? reply_cb;

	[GtkChild] protected unowned Gtk.Box status_box;
	[GtkChild] protected unowned Gtk.Box avatar_side;
	[GtkChild] protected unowned Gtk.Box title_box;
	[GtkChild] protected unowned Gtk.Box content_side;
	[GtkChild] protected unowned Gtk.FlowBox name_flowbox;
	[GtkChild] public unowned Gtk.MenuButton menu_button;

	[GtkChild] protected unowned Gtk.Image header_icon;
	[GtkChild] protected unowned Widgets.RichLabel header_label;
	[GtkChild] protected unowned Gtk.Button header_button;
	[GtkChild] public unowned Gtk.Image thread_line_top;
	[GtkChild] public unowned Gtk.Image thread_line_bottom;

	[GtkChild] public unowned Widgets.Avatar avatar;
	[GtkChild] public unowned Gtk.Overlay avatar_overlay;
	[GtkChild] protected unowned Gtk.Button name_button;
	[GtkChild] protected unowned Widgets.RichLabel name_label;
	[GtkChild] protected unowned Gtk.Label handle_label;
	[GtkChild] public unowned Gtk.Box indicators;
	[GtkChild] protected unowned Gtk.Label date_label;
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

	[GtkChild] protected unowned Gtk.Stack filter_stack;
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

	protected Adw.Bin emoji_reactions;
	public Gee.ArrayList<API.EmojiReaction>? reactions {
		get { return status.formal.compat_status_reactions; }
		set {
			if (emoji_reactions != null) content_column.remove (emoji_reactions);
			if (value == null) return;

			emoji_reactions = new ReactionsRow (value);
			content_column.insert_child_after (emoji_reactions, spoiler_stack);
		}
	}

	void settings_updated () {
		Tuba.toggle_css (this, settings.larger_font_size, "ttl-status-font-large");
		Tuba.toggle_css (this, settings.larger_line_height, "ttl-status-line-height-large");
		Tuba.toggle_css (this, settings.scale_emoji_hover, "lww-scale-emoji-hover");
	}

	construct {
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
	}

	private void on_name_button_clicked () {
		status.formal.account.open ();
	}

	private bool has_stats { get { return status.formal.reblogs_count != 0 || status.formal.favourites_count != 0; } }
	private void show_view_stats_action () {
		stats_simple_action.set_enabled (has_stats);
	}

	public Status (API.Status status) {
		Object (
			kind_instigator: status.account,
			status: status
		);

		if (kind == null && status.reblog != null) {
			kind = InstanceAccount.KIND_REMOTE_REBLOG;
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
		}
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

		if (status.formal.account.is_self ()) {
			pin_menu_item = new GLib.MenuItem (_("Pin"), "status.toggle-pinned");
			update_toggle_pinned_label ();
			pin_menu_item.set_attribute_value ("hidden-when", "action-disabled");

			menu_model.append_item (pin_menu_item);
			menu_model.append (_("Edit"), "status.edit-status");
			menu_model.append (_("Delete"), "status.delete-status");
		} else {
			menu_model.append (_("Report"), "status.report");
		}

		context_menu = new Gtk.PopoverMenu.from_model (menu_model);
	}

	private void copy_url () {
		Host.copy (status.formal.url ?? status.formal.account.url);
		app.toast (_("Copied post url to clipboard"));
	}

	private void open_in_browser () {
		Host.open_uri (status.formal.url ?? status.formal.account.url);
	}

	private void report_status () {
		new Dialogs.Report (status.formal.account, status.formal.id);
	}

	private void view_edit_history () {
		app.main_window.open_view (new Views.EditHistory (status.formal.id));
	}

	private void view_stats () {
		app.main_window.open_view (new Views.StatusStats (status.formal.id));
	}

	private void on_edit (API.Status x) {
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
		new Request.GET (@"/api/v1/statuses/$(status.formal.id)/source")
			.with_account (accounts.active)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				var source = API.StatusSource.from (node);

				new Dialogs.Compose.edit (status.formal, source, on_edit);
			})
			.on_error (() => {
				new Dialogs.Compose.edit (status.formal, null, on_edit);
			})
			.exec ();
	}

	private void delete_status () {
		app.question.begin (
			{_("Are you sure you want to delete this post?"), false},
			null,
			app.main_window,
			{ { _("Delete"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
			false,
			(obj, res) => {
				if (app.question.end (res).truthy ()) {
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
			}
		);
	}

	protected string spoiler_text {
		owned get {
			var text = status.formal.spoiler_text;
			if (text == null || text == "") {
				return _("Show More");
			} else {
				spoiler_text_revealed = text;
				return text;
			}
		}
	}
	public string spoiler_text_revealed { get; set; default = _("Sensitive"); }

	// separator between the bottom bar items
	string expanded_separator = "·";
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
				var date_parsed = new GLib.DateTime.from_iso8601 (status.formal.edited_at ?? status.formal.created_at, null);
				date_parsed = date_parsed.to_timezone (new TimeZone.local ());

				return date_parsed.format (@"$date_local $expanded_separator %H:%M").replace (" ", ""); // %e prefixes with whitespace on single digits
			} else {
				return DateTime.humanize (status.formal.edited_at ?? status.formal.created_at);
			}
		}
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
		accounts.active.describe_kind (this.kind, out res_kind, this.kind_instigator.display_name, this.kind_instigator.url);

		if (res_kind.icon == null) {
			//  status_box.margin_top = 18;
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
					overflow = Gtk.Overflow.HIDDEN
				};
				actor_avatar.add_css_class ("ttl-status-avatar-actor");

				if (this.kind_instigator != null) {
					actor_avatar_binding = this.bind_property ("kind_instigator", actor_avatar, "account", BindingFlags.SYNC_CREATE);
					actor_avatar.clicked.connect (open_kind_instigator_account);
				} else {
					actor_avatar_binding = status.bind_property ("account", actor_avatar, "account", BindingFlags.SYNC_CREATE);
					actor_avatar.clicked.connect (open_status_account);
				}
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

		if (header_button_activate > 0) header_button.disconnect (header_button_activate);
		if (header_kind_url != null)
			header_button_activate = header_button.clicked.connect (on_header_button_clicked);
	}

	private void on_header_button_clicked () {
		if (header_kind_url != null)
			header_label.on_activate_link (header_kind_url);
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

	public void show_toggle_pinned_action () {
		if (toggle_pinned_simple_action != null)
			toggle_pinned_simple_action.set_enabled (true);
	}

	private void update_toggle_pinned_label () {
		if (pin_menu_item != null)
			pin_menu_item.set_label (status?.formal?.pinned
				// translators: Unpin post from profile
				? _("Unpin")
				// translators: Pin post on profile
				: _("Pin")
			);
	}

	protected Gtk.Button prev_card;
	private Widgets.Attachment.Box attachments;
	private Widgets.VoteBox poll;
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

		this.content.mentions = status.formal.mentions;
		this.content.instance_emojis = status.formal.emojis_map;
		this.content.content = status.formal.content;

		if (quoted_status_btn != null) content_box.remove (quoted_status_btn);
		if (status.formal.quote != null && !is_quote) {
			try {
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
			} catch {
				critical (@"Widgets.Status ($(status.formal.id)): Couldn't build quote");
			}
		}

		spoiler_label.label = this.spoiler_text;
		spoiler_label_rev.label = this.spoiler_text_revealed;

		status.formal.tuba_spoiler_revealed = !status.formal.has_spoiler || settings.show_spoilers;
		update_spoiler_status ();

		handle_label.label = this.subtitle_text;
		date_label.label = this.date;

		pin_indicator.visible = status.formal.pinned;
		update_toggle_pinned_label ();
		edited_indicator.visible = status.formal.is_edited;
		edit_history_simple_action.set_enabled (status.formal.is_edited);

		var t_visibility = accounts.active.visibility[status.formal.visibility];
		visibility_indicator.icon_name = t_visibility.small_icon_name;
		visibility_indicator.tooltip_text = t_visibility.name;

		if (change_background_on_direct && status.formal.visibility == "direct") {
			this.add_css_class ("direct");
		} else {
			this.remove_css_class ("direct");
		}

		avatar.account = status.formal.account;
		reactions = status.formal.compat_status_reactions;

		name_label.instance_emojis = status.formal.account.emojis_map;
		name_label.label = title_text;

		if (poll != null) content_box.remove (poll);
		if (status.formal.poll != null) {
			poll = new Widgets.VoteBox ();
			bindings += status.formal.bind_property ("poll", poll, "poll", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
			content_box.append (poll);
		}

		if (attachments != null) content_box.remove (attachments);
		if (status.formal.has_media) {
			attachments = new Widgets.Attachment.Box ();
			attachments.has_spoiler = status.formal.sensitive;
			attachments.list = status.formal.media_attachments;
			content_box.append (attachments);
		}

		if (prev_card != null) content_box.remove (prev_card);
		if (settings.show_preview_cards && status.formal.card != null && status.formal.card.kind in ALLOWED_CARD_TYPES) {
			try {
				prev_card = (Gtk.Button) status.formal.card.to_widget ();
				prev_card.clicked.connect (open_card_url);
				content_box.append (prev_card);
			} catch {}
		}

		show_view_stats_action ();
		formal_handler_ids += status.formal.notify["reblogs-count"].connect (show_view_stats_action);
		formal_handler_ids += status.formal.notify["favourites-count"].connect (show_view_stats_action);
		formal_handler_ids += status.formal.notify["tuba-thread-role"].connect (install_thread_line);
		formal_handler_ids += status.formal.notify["tuba-spoiler-revealed"].connect (update_spoiler_status);
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
		API.PreviewCard.open_special_card (status.formal.card.card_special_type, status.formal.card.url);
	}

	private void on_reply (API.Status x) {
		if (reply_cb != null)
			reply_cb (x);
	}

	private void on_reply_button_clicked () {
		//  new Dialogs.Compose.reply (status.formal, on_reply);
		new Dialogs.NewCompose.reply (status.formal);
	}

	[GtkCallback] public void toggle_spoiler () {
		status.formal.tuba_spoiler_revealed = !status.formal.tuba_spoiler_revealed;
	}

	[GtkCallback] public void toggle_filter () {
		if (this.status.formal.filtered != null && this.status.formal.filtered.size > 0) {
			filter_stack.visible_child_name = filter_stack.visible_child_name == "filter" ? "status" : "filter";
		}
	}

	[GtkCallback] public void on_avatar_clicked () {
		status.formal.account.open ();
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
		name_flowbox.max_children_per_line = 1;
		name_flowbox.valign = Gtk.Align.CENTER;
		content_side.spacing = 10;

		// Remove the date & indicators
		indicators.remove (date_label);
		if (status.formal.is_edited)
			indicators.remove (edited_indicator);
		indicators.remove (visibility_indicator);

		date_label.label = this.date;
		date_label.wrap = true;

		// The bottom bar
		var bottom_info = new Gtk.FlowBox () {
			max_children_per_line = 150,
			margin_top = 6,
			selection_mode = Gtk.SelectionMode.NONE
		};

		// Insert it after the post content
		content_column.insert_child_after (bottom_info, spoiler_stack);
		bottom_info.append (date_label);
		if (status.formal.is_edited)
			bottom_info.append (edited_indicator);
		bottom_info.append (visibility_indicator);

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

			bottom_info.append (application_label);
		}

		add_separators_to_expanded_bottom (bottom_info);
	}

	// Adds *separator* between all *flowbox* children
	private void add_separators_to_expanded_bottom (Gtk.FlowBox flowbox, string separator = expanded_separator) {
		var i = 0;
		var child = flowbox.get_child_at_index (i);
		while (child != null) {
			if (i % 2 != 0) {
				flowbox.insert (new Gtk.Label (separator) { css_classes = {"dim-label"}, halign = Gtk.Align.START }, i);
			}

			i = i + 1;
			child = flowbox.get_child_at_index (i);
		}
	}

	// Threads
	public void install_thread_line () {
		if (expanded || !enable_thread_lines) return;

		switch (status.formal.tuba_thread_role) {
			case NONE:
				thread_line_top.visible = false;
				thread_line_bottom.visible = false;
				break;
			case START:
				thread_line_top.visible = false;
				thread_line_bottom.visible = true;
				break;
			case MIDDLE:
				thread_line_top.visible = true;
				thread_line_bottom.visible = true;
				break;
			case END:
				thread_line_top.visible = true;
				thread_line_bottom.visible = false;
				break;
		}
	}
}
