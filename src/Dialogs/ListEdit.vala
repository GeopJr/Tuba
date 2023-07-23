[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/list_edit.ui")]
public class Tuba.Dialogs.ListEdit : Adw.PreferencesWindow {
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

        public static RepliesPolicy from_string (string policy) {
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

    public ListEdit (API.List t_list) {
        list = t_list;
        title_row.text = t_list.title;

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
            .then ((sess, msg, in_stream) => {
                var parser = Network.get_parser_from_inputstream (in_stream);
                if (Network.get_array_size (parser) > 0) {
                    this.add (members_page);

                    Network.parse_array (msg, parser, node => {
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
    private bool on_close () {
        on_apply ();
        hide ();
        destroy ();

        return false;
    }

    private void on_apply () {
        if (list.title != list_title || RepliesPolicy.from_string (list.replies_policy) != replies_policy_active) {
            var replies_policy_string = replies_policy_active.to_string ();
            new Request.PUT (@"/api/v1/lists/$(list.id)")
                .with_account (accounts.active)
                .with_param ("title", list_title)
                .with_param ("replies_policy", replies_policy_string)
                .then (() => {
                    list.title = list_title;
                    list.replies_policy = replies_policy_string;
                })
                .exec ();
        }

        if (memebers_to_be_removed.size > 0) {
            var id_array = Request.array2string (memebers_to_be_removed, "account_ids");
            new Request.DELETE (@"/api/v1/lists/$(list.id)/accounts/?$id_array")
                .with_account (accounts.active)
                .exec ();
        }
    }
}
