[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/list_edit.ui")]
public class Tuba.Dialogs.ListEdit : Adw.PreferencesDialog {
	~ListEdit () {
		debug ("Destroying ListEdit");
	}

	public enum RepliesPolicy {
		NONE,
		LIST,
		FOLLOWED;

		public string to_string () {
			switch (this) {
				case LIST:
					return "list";
				case FOLLOWED:
					return "followed";
				default:
					return "none";
			}
		}

		public static RepliesPolicy from_string (string? policy) {
			switch (policy) {
				case "list":
					return LIST;
				case "followed":
					return FOLLOWED;
				default:
					return NONE;
			}
		}
	}

	private API.List list { get; set; }
	private Gee.ArrayList<string> memebers_to_be_removed { get; default=new Gee.ArrayList<string> (); }
	public RepliesPolicy replies_policy_active { get; private set; default=RepliesPolicy.NONE; }

	[GtkChild] unowned Adw.EntryRow title_row;
	[GtkChild] unowned Adw.SwitchRow hide_from_home_row;
	[GtkChild] unowned Gtk.CheckButton none_radio;
	[GtkChild] unowned Gtk.CheckButton list_radio;
	[GtkChild] unowned Gtk.CheckButton followed_radio;
	[GtkChild] unowned Adw.PreferencesPage members_page;
	[GtkChild] unowned Adw.PreferencesGroup members_group;

	public string list_title {
		get {
			return title_row.text;
		}
	}

	public bool is_exclusive {
		get {
			return hide_from_home_row.active;
		}
	}

	public ListEdit (API.List t_list) {
		list = t_list;
		title_row.text = t_list.title;
		hide_from_home_row.active = t_list.exclusive;

		update_active_radio_button (RepliesPolicy.from_string (t_list.replies_policy));
		update_members ();
	}

	[GtkCallback]
	private void on_radio_toggled () {
		if (none_radio.active) {
			replies_policy_active = RepliesPolicy.NONE;
			return;
		}

		if (list_radio.active) {
			replies_policy_active = RepliesPolicy.LIST;
			return;
		}

		if (followed_radio.active) {
			replies_policy_active = RepliesPolicy.FOLLOWED;
			return;
		}
	}

	private void update_active_radio_button (RepliesPolicy replies_policy) {
		switch (replies_policy) {
			case RepliesPolicy.LIST:
				list_radio.active = true;
				break;
			case RepliesPolicy.FOLLOWED:
				followed_radio.active = true;
				break;
			default:
				none_radio.active = true;
				break;
		}

		on_radio_toggled ();
	}

	private void update_members () {
		new Request.GET (@"/api/v1/lists/$(list.id)/accounts")
			.with_account (accounts.active)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				if (Network.get_array_size (parser) > 0) {
					this.add (members_page);

					Network.parse_array (parser, node => {
						var member = API.Account.from (node);
						var avi = new Widgets.Avatar () {
							account = member,
							size = 32
						};

						var m_switch = new Gtk.Switch () {
							active = true,
							state = true,
							valign = Gtk.Align.CENTER,
							halign = Gtk.Align.CENTER
						};

						m_switch.state_set.connect ((state) => {
							if (!state) {
								memebers_to_be_removed.add (member.id);
							} else if (memebers_to_be_removed.contains (member.id)) {
								memebers_to_be_removed.remove (member.id);
							}

							return state;
						});

						var member_row = new Adw.ActionRow () {
							title = member.full_handle
						};

						member_row.add_prefix (avi);
						member_row.add_suffix (m_switch);

						members_group.add (member_row);
					});
				}
			})
			.exec ();
	}

	[GtkCallback]
	private void on_close () {
		on_apply ();
		force_close ();
	}

	private void on_apply () {
		if (list.title != list_title || RepliesPolicy.from_string (list.replies_policy) != replies_policy_active || list.exclusive != is_exclusive) {
			var replies_policy_string = replies_policy_active.to_string ();

			var builder = new Json.Builder ();
			builder.begin_object ();
			builder.set_member_name ("title");
			builder.add_string_value (list_title);
			builder.set_member_name ("replies_policy");
			builder.add_string_value (replies_policy_string);
			builder.set_member_name ("exclusive");
			builder.add_boolean_value (is_exclusive);
			builder.end_object ();

			new Request.PUT (@"/api/v1/lists/$(list.id)")
				.with_account (accounts.active)
				.body_json (builder)
				.then (() => {
					list.title = list_title;
					list.replies_policy = replies_policy_string;
					list.exclusive = is_exclusive;
				})
				.exec ();
		}

		if (memebers_to_be_removed.size > 0) {
			var ids_builder = new Json.Builder ();
			ids_builder.begin_object ();
			ids_builder.set_member_name ("account_ids");
			ids_builder.begin_array ();
			memebers_to_be_removed.foreach (e => {
				ids_builder.add_string_value (e);
				return true;
			});
			ids_builder.end_array ();
			ids_builder.end_object ();

			new Request.DELETE (@"/api/v1/lists/$(list.id)/accounts")
				.with_account (accounts.active)
				.body_json (ids_builder)
				.exec ();
		}
	}
}
