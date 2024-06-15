public class Tuba.Widgets.Admin.EmailDomainBlock : Adw.ActionRow {
	public signal void removed (string email_domain_block_id);

	~EmailDomainBlock () {
		debug ("Destroying EmailDomainBlock");
	}

	string email_domain_block_id;
	public EmailDomainBlock (API.Admin.EmailDomainBlock email_domain_block) {
		email_domain_block_id = email_domain_block.id;
		this.title = email_domain_block.domain;

		int total_attempts = 0;
		if (email_domain_block.history != null) {
			email_domain_block.history.foreach ((entity) => {
				total_attempts += int.parse (entity.accounts) + int.parse (entity.uses);
				return true;
			});
		}

		// translators: subtitle on email domain blocks.
		//				The variable is the number of sing up
		//				attempts using said email domain.
		this.subtitle = _("%d Sign-up Attempts").printf (total_attempts);

		var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
			css_classes = { "circular", "flat", "error" },
			tooltip_text = _("Delete"),
			valign = Gtk.Align.CENTER
		};
		delete_button.clicked.connect (on_remove);
		this.add_suffix (delete_button);
	}

	public void on_remove () {
		removed (email_domain_block_id);
	}
}
