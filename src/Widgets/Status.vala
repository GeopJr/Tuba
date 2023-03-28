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

	[GtkChild] protected unowned Grid grid;

	[GtkChild] protected unowned Image header_icon;
	[GtkChild] protected unowned Widgets.RichLabelContainer header_label;
	[GtkChild] public unowned Image thread_line;

	[GtkChild] public unowned Widgets.Avatar avatar;
	[GtkChild] public unowned Overlay avatar_overlay;
	[GtkChild] protected unowned Widgets.RichLabelContainer name_label;
	[GtkChild] protected unowned Label handle_label;
	[GtkChild] protected unowned Box indicators;
	[GtkChild] protected unowned Label date_label;
	[GtkChild] protected unowned Image pin_indicator;
	[GtkChild] protected unowned Image edited_indicator;
	[GtkChild] protected unowned Image indicator;

	[GtkChild] protected unowned Box content_column;
	[GtkChild] protected unowned Stack spoiler_stack;
	[GtkChild] protected unowned Box content_box;
	[GtkChild] public unowned Widgets.MarkupView content;
	[GtkChild] protected unowned Widgets.Attachment.Box attachments;
	[GtkChild] protected unowned Button spoiler_button;
	[GtkChild] protected unowned Label spoiler_label;
	[GtkChild] protected unowned Label spoiler_label_rev;
	[GtkChild] protected unowned Box spoiler_status_con;

	[GtkChild] protected unowned Box status_stats;
	[GtkChild] protected unowned Label reblog_count_label;
	[GtkChild] protected unowned Label fav_count_label;

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

	protected GestureClick gesture_click_controller { get; set; }
	protected GestureLongPress gesture_lp_controller { get; set; }
	protected PopoverMenu context_menu { get; set; }
	private const GLib.ActionEntry[] action_entries = {
		{"copy-url",        copy_url},
		{"open-in-browser", open_in_browser}
	};
	private GLib.SimpleActionGroup action_group;
	private SimpleAction edit_history_simple_action;

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

		action_group = new GLib.SimpleActionGroup ();
		action_group.add_action_entries (action_entries, this);
		action_group.add_action(edit_history_simple_action);

		this.insert_action_group ("status", action_group);

		gesture_click_controller = new GestureClick();
		gesture_lp_controller = new GestureLongPress();
        add_controller(gesture_click_controller);
        add_controller(gesture_lp_controller);
		gesture_click_controller.button = Gdk.BUTTON_SECONDARY;
		gesture_lp_controller.button = Gdk.BUTTON_PRIMARY;
		gesture_lp_controller.touch_only = true;
        gesture_click_controller.pressed.connect(on_secondary_click);
        gesture_lp_controller.pressed.connect(on_secondary_click);
	}

	public Status (API.Status status) {
		Object (
			kind_instigator: status.account,
			status: status
		);

		if (kind == null && status.reblog != null) {
			kind = InstanceAccount.KIND_REMOTE_REBLOG;
		}

		check_actions();
		if (context_menu == null) {
			create_actions ();
		}
	}
	~Status () {
		message ("Destroying Status widget");
		if (context_menu != null) {
			context_menu.unparent ();
			context_menu.dispose();
		}
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

		var edit_history_menu_item = new MenuItem(_("View Edit History"), "status.edit-history");
		edit_history_menu_item.set_attribute_value("hidden-when", "action-disabled");
		menu_model.append_item (edit_history_menu_item);

		if (status.formal.account.is_self ()) {
			menu_model.append (_("Edit"), "status.edit-status");
			menu_model.append (_("Delete"), "status.delete-status");
		}

		context_menu = new PopoverMenu.from_model(menu_model);
		context_menu.set_parent(this);
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

	private void edit_status () {
		new Dialogs.Compose.edit (status.formal);
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
					.then ((sess, msg) => {
						var root = network.parse (msg);
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

	protected virtual void on_secondary_click () {
		gesture_click_controller.set_state(EventSequenceState.CLAIMED);
		gesture_lp_controller.set_state(EventSequenceState.CLAIMED);

		if (app.main_window.is_media_viewer_visible()) return;
		context_menu.popup();
	}

	private void check_actions() {
		if (kind == InstanceAccount.KIND_FOLLOW || kind == InstanceAccount.KIND_FOLLOW_REQUEST) {
			actions.visible = false;
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
	private Binding actor_avatar_binding;
	const string[] should_show_actor_avatar = {InstanceAccount.KIND_REBLOG, InstanceAccount.KIND_REMOTE_REBLOG, InstanceAccount.KIND_FAVOURITE};
	protected virtual void change_kind () {
		string icon = null;
		string descr = null;
		string label_url = null;
		check_actions();
		accounts.active.describe_kind (this.kind, out icon, out descr, this.kind_instigator, out label_url);

		header_icon.visible = header_label.visible = (icon != null);
		if (icon == null) {
			grid.margin_top = 8;
			return;
		};

		grid.margin_top = 0;

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
		header_label.dim = true;
		header_label.small_font = true;
		header_label.set_label(descr, label_url, this.kind_instigator.emojis_map);
	}

	private void open_kind_instigator_account () {
		this.kind_instigator.open ();
	}

	private void open_status_account () {
		status.account.open ();
	}

	// WARN: self_bindings __must__ be outside bind ()
	//       else some source values wont be updated
	BindingGroup self_bindings = new BindingGroup ();
	protected virtual void bind () {
		// WARN: formal_bindings __must__ be inside bind ()
		//       else the widget wont get destructed
		var formal_bindings = new BindingGroup ();

		self_bindings.bind_property ("spoiler-text", spoiler_label, "label", BindingFlags.SYNC_CREATE);
		self_bindings.bind_property ("spoiler-text-revealed", spoiler_label_rev, "label", BindingFlags.SYNC_CREATE);

		notify["reveal-spoiler"].connect(() => {
			spoiler_status_con.visible = reveal_spoiler && status.formal.has_spoiler;
			spoiler_stack.visible_child_name = reveal_spoiler ? "content" : "spoiler";
		});

		self_bindings.bind_property ("is-conversation-open", status_stats, "visible", BindingFlags.SYNC_CREATE);
		self_bindings.bind_property ("subtitle_text", handle_label, "label", BindingFlags.SYNC_CREATE);
		self_bindings.bind_property ("date", date_label, "label", BindingFlags.SYNC_CREATE);

		formal_bindings.bind_property ("pinned", pin_indicator, "visible", BindingFlags.SYNC_CREATE);
		formal_bindings.bind_property ("is-edited", edited_indicator, "visible", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			edit_history_simple_action.set_enabled(src.get_boolean());
			target.set_boolean (src.get_boolean());
			return true;
		});
		formal_bindings.bind_property ("visibility", indicator, "icon_name", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string (accounts.active.visibility[src.get_string ()].icon_name);
			return true;
		});
		formal_bindings.bind_property ("visibility", indicator, "tooltip-text", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string (accounts.active.visibility[src.get_string ()].name);
			return true;
		});
		formal_bindings.bind_property ("account", avatar, "account", BindingFlags.SYNC_CREATE);
		formal_bindings.bind_property ("compat-status-reactions", this, "reactions", BindingFlags.SYNC_CREATE);
		formal_bindings.bind_property ("has-spoiler", this, "reveal-spoiler", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_boolean (!src.get_boolean () || settings.show_spoilers);
			return true;
		});
		formal_bindings.bind_property ("content", content, "content", BindingFlags.SYNC_CREATE);
		formal_bindings.bind_property ("reblogs_count", reblog_count_label, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			int64 srcval = (int64) src;
			target.set_string (@"<b>$srcval</b> " + _("Boosts"));
			return true;
		});
		formal_bindings.bind_property ("favourites_count", fav_count_label, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			int64 srcval = (int64) src;
			target.set_string (@"<b>$srcval</b> " + _("Favorites"));
			return true;
		});
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
		name_label.set_label(title_text, status.formal.account.handle, status.formal.account.emojis_map, true);

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
		content.get_style_context ().add_class ("ttl-large-body");

		var content_grid = content_column.get_parent () as Grid;
		if (content_grid == null)
			return;
		var mgr = content_grid.get_layout_manager ();
		var child = mgr.get_layout_child (content_column);
		child.set_property ("column", 0);
		child.set_property ("column_span", 2);
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
		var l = thread_line;
		switch (thread_role) {
			case NONE:
				l.visible = false;
				l.remove_css_class("not-first");
				l.remove_css_class("not-last");
				break;
			case START:
				l.valign = Align.FILL;
				l.margin_top = 24;
				l.visible = true;
				l.remove_css_class("not-first");
				l.add_css_class("not-last");
				break;
			case MIDDLE:
				l.valign = Align.FILL;
				l.margin_top = 0;
				l.visible = true;
				l.add_css_class("not-first");
				l.add_css_class("not-last");
				break;
			case END:
				l.valign = Align.START;
				l.margin_top = 0;
				l.visible = true;
				l.add_css_class("not-first");
				break;
		}
	}

}
