public class Tuba.Widgets.Admin.AccountRow : Adw.ActionRow {
	public signal void account_opened (API.Admin.Account account_obj);

	~AccountRow () {
		debug ("Destroying AccountRow");
	}

	API.Admin.Account account_obj;
	public AccountRow (API.Admin.Account account) {
		account_obj = account;
		string ip = account.ip == null ? "" : @"$(account.ip)\n";
		string email = account.email == null ? "" : account.email;

		this.overflow = Gtk.Overflow.HIDDEN;
		this.subtitle_lines = 0;
		this.title = account.account.display_name;
		this.subtitle = @"$(account.account.full_handle)\n$(ip)$(email)";
		this.activated.connect (on_activate);
		this.activatable = true;

		this.add_prefix (new Widgets.Avatar () {
			account = account.account,
			size = 48,
			overflow = Gtk.Overflow.HIDDEN
		});

		string status = _("No Limits");
		if (account.suspended) {
			status = _("Suspended");
		} else if (account.silenced) {
			status = _("Limited");
		} else if (account.disabled) {
			status = _("Disabled");
		} else if (!account.approved) {
			// translators: admin panel, account waiting to be approved
			status = _("Waiting Approval");
		}

		this.add_suffix (new Gtk.Label (status) {
			xalign = 1.0f,
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			hexpand = true
		});
	}

	public void on_activate () {
		account_opened (account_obj);
	}
}
