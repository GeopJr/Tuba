using Gtk;
using Gdk;

[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/widgets/status.ui")]
public class Tuba.Widgets.Status : ListBoxRow {

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

	string? _kind = null;
	public string? kind {
		get { return _kind; }
		set {
			_kind = value;
			change_kind ();
		}
	}

	[GtkChild] protected unowned Box status_box;
	[GtkChild] protected unowned Box avatar_side;
	[GtkChild] protected unowned Box title_box;
	[GtkChild] protected unowned Box content_side;
	[GtkChild] protected unowned FlowBox name_flowbox;
	[GtkChild] public unowned MenuButton menu_button;

	[GtkChild] protected unowned Image header_icon;
	[GtkChild] protected unowned Widgets.RichLabel header_label;
	[GtkChild] protected unowned Button header_button;
	[GtkChild] public unowned Image thread_line_top;
	[GtkChild] public unowned Image thread_line_bottom;

	[GtkChild] public unowned Widgets.Avatar avatar;
	[GtkChild] public unowned Overlay avatar_overlay;
	[GtkChild] protected unowned Button name_button;
	[GtkChild] protected unowned Widgets.RichLabel name_label;
	[GtkChild] protected unowned Label handle_label;
	[GtkChild] protected unowned Box indicators;
	[GtkChild] protected unowned Label date_label;
	[GtkChild] protected unowned Image pin_indicator;
	[GtkChild] protected unowned Image edited_indicator;
	[GtkChild] protected unowned Image visibility_indicator;

	[GtkChild] protected unowned Box content_column;
	[GtkChild] protected unowned Stack spoiler_stack;
	[GtkChild] protected unowned Box content_box;
	[GtkChild] public unowned Widgets.MarkupView content;
	[GtkChild] protected unowned Widgets.Attachment.Box attachments;
	[GtkChild] protected unowned Button spoiler_button;
	[GtkChild] protected unowned Label spoiler_label;
	[GtkChild] protected unowned Label spoiler_label_rev;
	[GtkChild] protected unowned Box spoiler_status_con;

	[GtkChild] public unowned FlowBox emoji_reactions;
	[GtkChild] public unowned Box actions;
	[GtkChild] public unowned Box fr_actions;

	[GtkChild] public unowned Button accept_fr_button;
	[GtkChild] public unowned Button decline_fr_button;

	[GtkChild] public unowned Widgets.VoteBox poll;

	protected Button reply_button;
	protected Adw.ButtonContent reply_button_content;
	protected StatusActionButton reblog_button;
	protected StatusActionButton favorite_button;
	protected StatusActionButton bookmark_button;

	protected PopoverMenu context_menu { get; set; }
	private const GLib.ActionEntry[] action_entries = {
		{"copy-url",        copy_url},
		{"open-in-browser", open_in_browser}
	};
	private GLib.SimpleActionGroup action_group;
	private SimpleAction edit_history_simple_action;
	private SimpleAction stats_simple_action;

	public bool is_conversation_open { get; set; default = false; }

	public Gee.ArrayList<API.EmojiReaction>? reactions {
		get { return status.formal.compat_status_reactions; }
		set {
			if (value == null) return;

			var i = 0;
			FlowBoxChild? fb_child = null;
			while((fb_child = emoji_reactions.get_child_at_index(i)) != null) {
				emoji_reactions.remove(fb_child);
				i = i + 1;
			}

			foreach (API.EmojiReaction p in value){
				if (p.count <= 0) return;

				var badge_button = new Button() {
					// translators: the variable is the emoji or its name if it's custom
					tooltip_text = _("React with %s").printf (p.name)
				};
				var badge = new Box(Orientation.HORIZONTAL, 6);

				if (p.url != null) {
					badge.append(new Widgets.Emoji(p.url));
				} else {
					badge.append(new Label(p.name));
				}

				badge.append(new Label(@"$(p.count)"));
				badge_button.child = badge;

				if (p.me == true) {
					badge_button.add_css_class("accent");
				}

				//  emoji_reactions.append(badge_button); // GTK >= 4.5
				emoji_reactions.insert (badge_button, -1);
			}

			emoji_reactions.visible = value.size > 0;
		}
	}

	construct {
		name_label.use_markup = false;
		avatar_overlay.set_size_request(avatar.size, avatar.size);
		open.connect (on_open);
		if (settings.larger_font_size)
			add_css_class("ttl-status-font-large");

		if (settings.larger_line_height)
			add_css_class("ttl-status-line-height-large");

		rebuild_actions ();

		settings.notify["larger-font-size"].connect (() => {
			if (settings.larger_font_size) {
				add_css_class("ttl-status-font-large");
			} else {
				remove_css_class("ttl-status-font-large");
			}
		});
		settings.notify["larger-line-height"].connect (() => {
			if (settings.larger_line_height) {
				add_css_class("ttl-status-line-height-large");
			} else {
				remove_css_class("ttl-status-line-height-large");
			}
		});

		edit_history_simple_action = new SimpleAction ("edit-history", null);
		edit_history_simple_action.activate.connect (view_edit_history);

		stats_simple_action = new SimpleAction ("status-stats", null);
		stats_simple_action.activate.connect (view_stats);

		action_group = new GLib.SimpleActionGroup ();
		action_group.add_action_entries (action_entries, this);
		action_group.add_action(stats_simple_action);
		action_group.add_action(edit_history_simple_action);

		this.insert_action_group ("status", action_group);

		name_button.clicked.connect (() => name_label.on_activate_link(status.formal.account.handle));

		show_view_stats_action ();
		reblog_button.content.notify["label"].connect (show_view_stats_action);
		favorite_button.content.notify["label"].connect (show_view_stats_action);
	}

	private bool has_stats { get { return reblog_button.content.label != "" || favorite_button.content.label != ""; } }
	private void show_view_stats_action () {
		stats_simple_action.set_enabled(has_stats);
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
		message ("Destroying Status widget");
		if (context_menu != null) {
			context_menu.dispose();
		}
	}

	protected void init_menu_button () {
		check_actions();
		if (context_menu == null) {
			create_actions ();
		}
		menu_button.popover = context_menu;
		menu_button.visible = true;
	}

	protected void create_actions () {
		create_context_menu();

		if (status.formal.account.is_self ()) {
			var edit_status_simple_action = new SimpleAction ("edit-status", null);
			edit_status_simple_action.activate.connect (edit_status);
			action_group.add_action(edit_status_simple_action);

			var delete_status_simple_action = new SimpleAction ("delete-status", null);
			delete_status_simple_action.activate.connect (delete_status);
			action_group.add_action(delete_status_simple_action);
		}
	}

	protected void create_context_menu() {
		var menu_model = new GLib.Menu ();
		menu_model.append (_("Open in Browser"), "status.open-in-browser");
		menu_model.append (_("Copy URL"), "status.copy-url");

		// translators: as in post stats (who liked and boosted)
		var stats_menu_item = new MenuItem(_("View Stats"), "status.status-stats");
		stats_menu_item.set_attribute_value("hidden-when", "action-disabled");
		menu_model.append_item (stats_menu_item);

		var edit_history_menu_item = new MenuItem(_("View Edit History"), "status.edit-history");
		edit_history_menu_item.set_attribute_value("hidden-when", "action-disabled");
		menu_model.append_item (edit_history_menu_item);

		if (status.formal.account.is_self ()) {
			menu_model.append (_("Edit"), "status.edit-status");
			menu_model.append (_("Delete"), "status.delete-status");
		}

		context_menu = new PopoverMenu.from_model(menu_model);
	}

	private void copy_url () {
		Host.copy (status.formal.url ?? status.formal.account.url);
	}

	private void open_in_browser () {
		Host.open_uri (status.formal.url ?? status.formal.account.url);
	}

	private void view_edit_history () {
		app.main_window.open_view (new Views.EditHistory (status.formal.id));
	}

	private void view_stats () {
		app.main_window.open_view (new Views.StatusStats (status.formal.id));
	}

	private void edit_status () {
		new Request.GET (@"/api/v1/statuses/$(status.formal.id)/source")
			.with_account (accounts.active)
			.then ((sess, msg, in_stream) => {
				var parser = Network.get_parser_from_inputstream(in_stream);
				var node = network.parse_node (parser);
				var source = API.StatusSource.from (node);

				new Dialogs.Compose.edit (status.formal, source);
			})
			.on_error (() => {
				new Dialogs.Compose.edit (status.formal);
			})
			.exec ();
	}

	private void delete_status () {
		var remove = app.question (
			_("Are you sure you want to delete this post?"),
			null,
			app.main_window,
			_("Delete"),
			Adw.ResponseAppearance.DESTRUCTIVE
		);

		remove.response.connect(res => {
			if (res == "yes") {
				new Request.DELETE (@"/api/v1/statuses/$(status.formal.id)")
					.with_account (accounts.active)
					.then ((sess, msg, in_stream) => {
						var parser = Network.get_parser_from_inputstream(in_stream);
						var root = network.parse (parser);
						if (root.has_member("error")) {
							// TODO: Handle error (probably a toast?)
						};
					})
					.exec ();
			}
			remove.destroy();
		});

		remove.present ();
	}

	private void check_actions() {
		if (kind == InstanceAccount.KIND_FOLLOW || kind == InstanceAccount.KIND_FOLLOW_REQUEST) {
			actions.visible = false;
			visibility_indicator.visible = false;
			date_label.visible = false;
		}
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
	public bool reveal_spoiler { get; set; default = true; }

	protected string date {
		owned get {
			return DateTime.humanize (status.formal.created_at);
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
	ulong actor_avatar_singal;
	ulong header_button_activate;
	private Binding actor_avatar_binding;
	const string[] should_show_actor_avatar = {InstanceAccount.KIND_REBLOG, InstanceAccount.KIND_REMOTE_REBLOG, InstanceAccount.KIND_FAVOURITE};
	protected virtual void change_kind () {
		string icon = null;
		string descr = null;
		string label_url = null;
		check_actions();
		accounts.active.describe_kind (this.kind, out icon, out descr, this.kind_instigator, out label_url);

		if (icon == null) {
			//  status_box.margin_top = 18;
			return;
		};

		header_icon.visible = header_button.visible = true;
		//  status_box.margin_top = 15;

		if (kind in should_show_actor_avatar) {
			if (actor_avatar == null) {
				actor_avatar = new Widgets.Avatar () {
					size = 34,
					valign = Gtk.Align.START,
					halign = Gtk.Align.START,
					css_classes = {"ttl-status-avatar-actor"}
				};

				if (this.kind_instigator != null) {
					actor_avatar_binding = this.bind_property ("kind_instigator", actor_avatar, "account", BindingFlags.SYNC_CREATE);
					actor_avatar_singal = actor_avatar.clicked.connect(open_kind_instigator_account);
				} else {
					actor_avatar_binding = status.bind_property ("account", actor_avatar, "account", BindingFlags.SYNC_CREATE);
					actor_avatar_singal = actor_avatar.clicked.connect(open_status_account);
				}
			}
			avatar.add_css_class("ttl-status-avatar-border");
			avatar_overlay.child = actor_avatar;
		} else if (actor_avatar != null) {
			actor_avatar.disconnect(actor_avatar_singal);
			actor_avatar_binding.unbind();

			avatar_overlay.child = null;
		}

		header_icon.icon_name = icon;
		header_label.instance_emojis = this.kind_instigator.emojis_map;
		header_label.label = descr;

		if (header_button_activate > 0) header_button.disconnect(header_button_activate);
		header_button_activate = header_button.clicked.connect (() => header_label.on_activate_link(label_url));
	}

	private void open_kind_instigator_account () {
		this.kind_instigator.open ();
	}

	private void open_status_account () {
		status.account.open ();
	}

	// WARN: self_bindings __must__ be outside bind ()
	//       else some source values won't be updated
	BindingGroup self_bindings = new BindingGroup ();
	protected virtual void bind () {
		// WARN: formal_bindings __must__ be inside bind ()
		//       else the widget won't get destructed
		var formal_bindings = new BindingGroup ();

		this.content.instance_emojis = status.formal.emojis_map;
		this.content.content = status.formal.content;

		self_bindings.bind_property ("spoiler-text", spoiler_label, "label", BindingFlags.SYNC_CREATE);
		self_bindings.bind_property ("spoiler-text-revealed", spoiler_label_rev, "label", BindingFlags.SYNC_CREATE);

		notify["reveal-spoiler"].connect(() => {
			spoiler_status_con.visible = reveal_spoiler && status.formal.has_spoiler;
			spoiler_stack.visible_child_name = reveal_spoiler ? "content" : "spoiler";
		});

		self_bindings.bind_property ("subtitle_text", handle_label, "label", BindingFlags.SYNC_CREATE);
		self_bindings.bind_property ("date", date_label, "label", BindingFlags.SYNC_CREATE);

		formal_bindings.bind_property ("pinned", pin_indicator, "visible", BindingFlags.SYNC_CREATE);
		formal_bindings.bind_property ("is-edited", edited_indicator, "visible", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			edit_history_simple_action.set_enabled(src.get_boolean());
			target.set_boolean (src.get_boolean());
			return true;
		});
		formal_bindings.bind_property ("visibility", visibility_indicator, "icon_name", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string (accounts.active.visibility[src.get_string ()].icon_name);
			return true;
		});
		formal_bindings.bind_property ("visibility", visibility_indicator, "tooltip-text", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string (accounts.active.visibility[src.get_string ()].name);
			return true;
		});
		formal_bindings.bind_property ("account", avatar, "account", BindingFlags.SYNC_CREATE);
		formal_bindings.bind_property ("compat-status-reactions", this, "reactions", BindingFlags.SYNC_CREATE);
		formal_bindings.bind_property ("has-spoiler", this, "reveal-spoiler", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_boolean (!src.get_boolean () || settings.show_spoilers);
			return true;
		});
		//  formal_bindings.bind_property ("content", content, "content", BindingFlags.SYNC_CREATE);
		formal_bindings.bind_property ("reblogs_count", reblog_button.content, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			int64 srcval = (int64) src;

			if (srcval > 0) {
				reblog_button.content.margin_start = 12;
				reblog_button.content.margin_end = 9;
				target.set_string (@"$srcval");
			} else {
				reblog_button.content.margin_start = 0;
				reblog_button.content.margin_end = 0;
				target.set_string ("");
			}

			return true;
		});
		formal_bindings.bind_property ("favourites_count", favorite_button.content, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			int64 srcval = (int64) src;

			if (srcval > 0) {
				favorite_button.content.margin_start = 12;
				favorite_button.content.margin_end = 9;
				target.set_string (@"$srcval");
			} else {
				favorite_button.content.margin_start = 0;
				favorite_button.content.margin_end = 0;
				target.set_string ("");
			}

			return true;
		});
		formal_bindings.bind_property ("replies_count", reply_button_content, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			int64 srcval = (int64) src;

			if (srcval > 0) {
				reply_button_content.margin_start = 12;
				reply_button_content.margin_end = 9;
				target.set_string (@"$srcval");
			} else {
				reply_button_content.margin_start = 0;
				reply_button_content.margin_end = 0;
				target.set_string ("");
			}

			return true;
		});
		// Attachments
		formal_bindings.bind_property ("media-attachments", attachments, "list", BindingFlags.SYNC_CREATE);

		self_bindings.set_source (this);
		formal_bindings.set_source (status.formal);

		// TODO: Ideally, this should be a binding too somehow
		// bind_property ("title_text", name_label, "label", BindingFlags.SYNC_CREATE);
		//  name_label.set_label(title_text, status.formal.account.handle, status.formal.account.emojis_map, true);
		name_label.instance_emojis = status.formal.account.emojis_map;
		name_label.label = title_text;

		// Actions
		reblog_button.bind (status.formal);
		favorite_button.bind (status.formal);
		bookmark_button.bind (status.formal);

		reply_button.set_child(reply_button_content);
		reply_button.add_css_class("ttl-status-action-reply");
		reply_button.tooltip_text = _("Reply");
		if (status.formal.in_reply_to_id != null)
			reply_button_content.icon_name = "tuba-reply-all-symbolic";
		else
			reply_button_content.icon_name = "tuba-reply-sender-symbolic";

		if (!status.can_be_boosted) {
			reblog_button.sensitive = false;
			reblog_button.tooltip_text = _("This post can't be boosted");
			reblog_button.content.icon_name = accounts.active.visibility[status.visibility].icon_name;
		}
		else {
			reblog_button.sensitive = true;
			reblog_button.tooltip_text = _("Boost");
			reblog_button.content.icon_name = "tuba-media-playlist-repeat-symbolic";
		}

		if (status.id == "") {
			actions.destroy ();
			date_label.destroy ();
		}

		// TODO: Votebox should be created dynamically if needed.
		// Currently *all* status widgets contain one even if they don't have a poll.
		if (status.formal.poll==null){
			poll.hide();
		} else {
			poll.status_parent=status.formal;
			status.formal.bind_property ("poll", poll, "poll", BindingFlags.SYNC_CREATE);
		}
	}

	protected virtual void append_actions () {
		reply_button = new Button ();
		reply_button_content = new Adw.ButtonContent ();
		reply_button.clicked.connect (() => new Dialogs.Compose.reply (status.formal));
		actions.append (reply_button);

		reblog_button = new StatusActionButton () {
			prop_name = "reblogged",
			action_on = "reblog",
			action_off = "unreblog"
		};
		reblog_button.add_css_class("ttl-status-action-reblog");
		reblog_button.tooltip_text = _("Boost");
		actions.append (reblog_button);

		favorite_button = new StatusActionButton () {
			prop_name = "favourited",
			action_on = "favourite",
			action_off = "unfavourite",
			icon_name = "tuba-unstarred-symbolic",
			icon_toggled_name = "tuba-starred-symbolic"
		};
		favorite_button.add_css_class("ttl-status-action-star");
		favorite_button.tooltip_text = _("Favorite");
		actions.append (favorite_button);

		bookmark_button = new StatusActionButton () {
			prop_name = "bookmarked",
			action_on = "bookmark",
			action_off = "unbookmark",
			icon_name = "tuba-bookmarks-symbolic",
			icon_toggled_name = "tuba-bookmarks-filled-symbolic"
		};
		bookmark_button.add_css_class("ttl-status-action-bookmark");
		bookmark_button.tooltip_text = _("Bookmark");
		actions.append (bookmark_button);
	}

	void rebuild_actions () {
		for (var w = actions.get_first_child (); w != null; w = w.get_next_sibling ())
			actions.remove (w);

		append_actions ();

		// var menu_button = new MenuButton (); //TODO: Status menu
		// menu_button.icon_name = "tuba-view-more-symbolic";
		// menu_button.get_first_child ().add_css_class ("flat");
		// actions.append (menu_button);

		for (var w = actions.get_first_child (); w != null; w = w.get_next_sibling ()) {
			w.add_css_class ("flat");
			w.add_css_class ("circular");
			w.halign = Align.START;
			w.hexpand = true;
		}

		var w = actions.get_last_child ();
		w.hexpand = false;
	}

	[GtkCallback] public void toggle_spoiler () {
		reveal_spoiler = !reveal_spoiler;
	}

	[GtkCallback] public void on_avatar_clicked () {
		status.formal.account.open ();
	}

	public void expand_root () {
		activatable = false;
		content.selectable = true;
		content.add_css_class ("ttl-large-body");

		// separator between the bottom bar items
		var separator = "·";

		// Move the avatar & thread line into the name box
		status_box.remove(avatar_side);
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

		// Re-parse the date into a MONTH DAY, YEAR (separator) HOUR:MINUTES
		var date_parsed = new GLib.DateTime.from_iso8601 (status.formal.created_at, null);
		date_label.label = date_parsed.format(@"%B %e, %Y $separator %H:%M").replace(" ", ""); // %e prefixes with whitespace on single digits
		date_label.wrap = true;

		// The bottom bar
		var bottom_info = new Gtk.FlowBox () {
			max_children_per_line = 100,
			margin_top = 6,
			selection_mode = SelectionMode.NONE
		};

		// Insert it after the post content
		content_column.insert_child_after (bottom_info, spoiler_stack);
		bottom_info.append (date_label);
		if (status.formal.is_edited)
			bottom_info.append (edited_indicator);
		bottom_info.append (visibility_indicator);

		edited_indicator.valign = Gtk.Align.CENTER;
		visibility_indicator.valign = Gtk.Align.CENTER;

		// Make the icons smaller
		edited_indicator.pixel_size = 14;
		visibility_indicator.pixel_size = 14;

		// If the application used to make the post is available
		if (status.formal.application != null) {
			var has_link = status.formal.application.website != null;
			// Make it an anchor if it has a website
			var application_link = has_link ? @"<a href=\"$(status.formal.application.website)\">$(status.formal.application.name)</a>" : status.formal.application.name;
			var application_label = new Gtk.Label(application_link) {
				wrap = true,
				use_markup = has_link,
				halign = Gtk.Align.START
			};

			// If it's not an anchor, it should follow the styling of the other items
			if (!has_link) application_label.add_css_class ("dim-label");

			bottom_info.append (application_label);
		}

		add_separators_to_expanded_bottom (bottom_info, separator);
	}

	// Adds *separator* between all *flowbox* children
	private void add_separators_to_expanded_bottom (FlowBox flowbox, string separator = "·") {
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

	public enum ThreadRole {
		NONE,
		START,
		MIDDLE,
		END;

		public static void connect_posts (Widgets.Status? prev, Widgets.Status curr) {
			if (prev == null) {
				curr.thread_role = NONE;
				return;
			}

			switch (prev.thread_role) {
				case NONE:
					prev.thread_role = START;
					curr.thread_role = END;
					break;
				default:
					prev.thread_role = MIDDLE;
					curr.thread_role = END;
					break;
			}
		}
	}

	public ThreadRole thread_role { get; set; default = ThreadRole.NONE; }

	public void install_thread_line () {
		var l_t = thread_line_top;
		var l_b = thread_line_bottom;
		switch (thread_role) {
			case NONE:
				l_t.visible = false;
				l_b.visible = false;
				break;
			case START:
				l_t.visible = false;
				l_b.visible = true;
				break;
			case MIDDLE:
				l_t.visible = true;
				l_b.visible = true;
				break;
			case END:
				l_t.visible = true;
				l_b.visible = false;
				break;
		}
	}

}
