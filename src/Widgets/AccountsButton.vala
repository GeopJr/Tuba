using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/accounts_button.ui")]
public class Tootle.Widgets.AccountsButton : Gtk.MenuButton, IAccountListener {

	[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/accounts_button_item.ui")]
	class Item : ListBoxRow {

		AccountsButton button;
		InstanceAccount account;

		[GtkChild]
		Stack stack;
		[GtkChild]
		Widgets.Avatar avatar;
		[GtkChild]
		Label title;
		[GtkChild]
		Label handle;
		[GtkChild]
		Button forget_button;

		public Item (InstanceAccount account, AccountsButton btn) {
			this.account = account;
			this.button = btn;
			avatar.url = account.avatar;
			title.label = account.display_name;
			handle.label = account.handle;
		}

		public Item.add_new () {
			forget_button.destroy ();
			stack.visible_child_name = "new";
			selectable = false;
		}

		[GtkCallback]
		void forget () {
			var forget = app.question (
				_("Forget %s?".printf (handle.label)),
				_("This account will be removed from the application."),
				window
			);
			if (forget) {
				button.active = false;
				accounts.remove (account);
			}
		}

		[GtkCallback]
		void open_profile () {
			button.active = false;
			account.resolve_open (accounts.active);
		}

	}

	bool invalidated = true;

	[GtkChild]
	Widgets.Avatar avatar;

	[GtkChild]
	ListBox account_list;

	[GtkChild]
	ModelButton item_accounts;
	[GtkChild]
	ModelButton item_prefs;
	[GtkChild]
	ModelButton item_refresh;
	[GtkChild]
	ModelButton item_search;
	[GtkChild]
	Button item_favs;
	[GtkChild]
	Button item_conversations;
	[GtkChild]
	Button item_bookmarks;
	[GtkChild]
	Button item_lists;

	construct {
		account_listener_init ();

		item_refresh.clicked.connect (() => {
			app.refresh ();
		});

		item_favs.clicked.connect (() => {
			window.open_view (new Views.Favorites ());
			popover.popdown ();
		});
		item_conversations.clicked.connect (() => {
			window.open_view (new Views.Conversations ());
			popover.popdown ();
		});
		item_bookmarks.clicked.connect (() => {
			window.open_view (new Views.Bookmarks ());
			popover.popdown ();
		});
		item_lists.clicked.connect (() => {
			window.open_view (new Views.Lists ());
			popover.popdown ();
		});
		item_search.clicked.connect (() => {
			window.open_view (new Views.Search ());
			popover.popdown ();
		});
		item_prefs.clicked.connect (() => {
			Dialogs.Preferences.open ();
			popover.popdown ();
		});

		notify["active"].connect (() => {
			if (active && invalidated)
				rebuild ();
		});

		account_list.row_activated.connect (on_selection_changed);
	}
	~AccountsButton () {
		account_listener_free ();
	}

	protected void on_selection_changed (ListBoxRow r) {
		var i = r.get_index ();
		if (i >= accounts.saved.size) {
			active = false;
			new Dialogs.NewAccount ();
			popover.popdown ();
			return;
		}

		var account = accounts.saved.@get (i);
		if (accounts.active == account)
			return;

		accounts.switch_account (i);
		popover.popdown ();
	}

	public virtual void on_accounts_changed (Gee.ArrayList<InstanceAccount> accounts) {
		invalidated = true;
		if (active)
			rebuild ();
	}

	public virtual void on_account_changed (InstanceAccount? account) {
		if (account == null) {
			avatar.url = null;
			item_accounts.text = "<b><span size=\"large\">%s</span></b>\n%s".printf (
				_("Anonymous"),
				_("No active account"));
		}
		else {
			avatar.url = account.avatar;
			item_accounts.text = @"<b><span size=\"large\">$(account.display_name)</span></b>\n$(account.handle)";
		}
		item_accounts.use_markup = true;
	}

	void rebuild () {
		account_list.@foreach (w => account_list.remove (w));
		accounts.saved.@foreach (acc => {
			var row = new Item (acc, this);
			account_list.insert (row, -1);
			if (accounts.active == acc)
				row.activate ();

			return true;
		});
		account_list.insert (new Item.add_new (), -1);

		invalidated = false;
	}

}
