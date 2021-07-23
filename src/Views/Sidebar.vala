using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/sidebar/view.ui")]
public class Tootle.Views.Sidebar : Box, AccountHolder {

	[GtkChild] unowned ToggleButton accounts_button;
	[GtkChild] unowned Stack mode;
	[GtkChild] unowned ListBox items;
	[GtkChild] unowned ListBox saved_accounts;

	[GtkChild] unowned Widgets.Avatar avatar;
	[GtkChild] unowned Label title;
	[GtkChild] unowned Label subtitle;

	protected InstanceAccount? account { get; set; default = null; }
	GLib.ListStore item_model = new GLib.ListStore (typeof (Object));

	Item item_preferences = new Item () {
			label = _("Preferences"),
			icon = "emblem-system-symbolic",
			selectable = false,
			separated = true,
			on_activated = () => {
				Dialogs.Preferences.open ();
			}
	};
	Item item_about = new Item () {
			label = _("About"),
			icon = "help-about-symbolic",
			selectable = false,
			on_activated = () => {
				app.lookup_action ("about").activate (null);
			}
	};

	construct {
		construct_account_holder ();
		items.bind_model (item_model, on_item_create);
		items.set_header_func (on_item_header_update);
		saved_accounts.set_header_func (on_account_header_update);
	}

	protected virtual void on_accounts_changed (Gee.ArrayList<InstanceAccount> accounts) {
		for (var w = saved_accounts.get_first_child (); w != null; w = w.get_next_sibling ()) {
			saved_accounts.remove (w);
		}

		accounts.foreach (acc => {
			saved_accounts.append (new AccountRow (acc));
			return true;
		});

		var new_acc_row = new AccountRow (null);
		saved_accounts.append (new_acc_row);
	}

	protected virtual void on_account_changed (InstanceAccount? account) {
		this.account = account;

		warning (account.handle);
		accounts_button.active = false;
		item_model.remove_all ();

		if (account != null) {
			title.label = account.display_name;
			subtitle.label = account.handle;
			avatar.account = account;

			account.populate_user_menu (item_model);
		}
		else {
			saved_accounts.unselect_all ();

			title.label = _("Anonymous");
			subtitle.label = _("No account selected");
			avatar.account = null;
		}

		item_model.append (item_preferences);
		item_model.append (item_about);

		// item_model.append (new Item () {
		// 	label = "(Debug) Empty View",
		// 	separated = true,
		// 	on_activated = () => {
		// 		app.main_window.open_view (new Views.ContentBase ());
		// 	}
		// });
	}

	[GtkCallback] void on_mode_changed () {
		mode.visible_child_name = accounts_button.active ? "saved_accounts" : "items";
	}



	// Item

	public class Item : Object {
		public VoidFunc? on_activated;
		public string label { get; set; default = ""; }
		public string icon { get; set; default = ""; }
		public int badge { get; set; default = 0; }
		public bool selectable { get; set; default = false; }
		public bool separated { get; set; default = false; }
	}

	[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/sidebar/item.ui")]
	protected class ItemRow : ListBoxRow {
		public Item item;

		[GtkChild] unowned Image icon;
		[GtkChild] unowned Label label;
		[GtkChild] unowned Label badge;

		public ItemRow (Item _item) {
			item = _item;
			item.bind_property ("label", label, "label", BindingFlags.SYNC_CREATE);
			item.bind_property ("icon", icon, "icon-name", BindingFlags.SYNC_CREATE);
			item.bind_property ("badge", badge, "label", BindingFlags.SYNC_CREATE);
			item.bind_property ("badge", badge, "visible", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
				target.set_boolean (src.get_int () > 0);
				return true;
			});
			bind_property ("selectable", item, "selectable", BindingFlags.SYNC_CREATE);
		}
	}

	Widget on_item_create (Object obj) {
		return new ItemRow (obj as Item);
	}

	[GtkCallback] void on_item_activated (ListBoxRow _row) {
		var row = _row as ItemRow;
		if (row.item.on_activated != null)
			row.item.on_activated ();

        var flap = app.main_window.flap;
        if (flap.folded)
		    flap.reveal_flap = false;
	}

	void on_item_header_update (ListBoxRow _row, ListBoxRow? _before) {
		var row = _row as ItemRow;
		var before = _before as ItemRow;

		row.set_header (null);

		if (row.item.separated && before != null && !before.item.separated) {
			row.set_header (new Separator (Orientation.HORIZONTAL));
		}
	}



	// Account

	[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/sidebar/account.ui")]
	protected class AccountRow : Adw.ActionRow {
		public InstanceAccount? account;

		[GtkChild] unowned Widgets.Avatar avatar;
		[GtkChild] unowned Button forget;

		public AccountRow (InstanceAccount? _account) {
			account = _account;
			if (account != null) {
				title = account.display_name;
				subtitle = account.handle;
				avatar.account = account;
			}
			else {
				title = _("Add Account");
				avatar.account = null;
				selectable = false;
				forget.hide ();
			}
		}

		[GtkCallback] void on_forget () {
			var confirmed = app.question (
				_("Forget %s?".printf (account.handle)),
				_("This account will be removed from the application."),
				app.main_window
			);
			if (confirmed) {
				try {
					accounts.remove (account);
				}
				catch (Error e) {
					warning (e.message);
					app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
				}
			}
		}

	}

	void on_account_header_update (ListBoxRow _row, ListBoxRow? _before) {
		var row = _row as AccountRow;

		row.set_header (null);

		if (row.account == null && _before != null)
			row.set_header (new Separator (Orientation.HORIZONTAL));
	}

	[GtkCallback] void on_account_activated (ListBoxRow _row) {
		var row = _row as AccountRow;
		if (row.account != null)
			accounts.activate (row.account);
		else
			new Dialogs.NewAccount ().present ();
	}

}
