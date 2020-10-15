using Gtk;

public class Tootle.Views.Main : Views.TabbedBase {

	public Widgets.AccountsButton account_button;
	public Button compose_button;
	public Button search_button;

	public Main () {
		add_tab (new Views.Home ());
		add_tab (new Views.Notifications ());
		add_tab (new Views.Local ());
		add_tab (new Views.Federated ());
	}

	public override void build_header () {
		base.build_header ();
		back_button.visible = false;

		account_button = new Widgets.AccountsButton ();
		account_button.show ();
		header.pack_start (account_button);

		compose_button = new Button.from_icon_name ("document-edit-symbolic");
		compose_button.tooltip_text = _("Compose");
		compose_button.action_name = "app.compose";
		compose_button.show ();
		header.pack_start (compose_button);

		search_button = new Button.from_icon_name ("edit-find-symbolic");
		search_button.tooltip_text = _("Search");
		search_button.action_name = "app.search";
		search_button.show ();
		header.pack_end (search_button);
	}

}
