using Gtk;

public class Tuba.Widgets.Conversation : Widgets.Status {

	public API.Conversation conversation { get; construct set; }

	public Conversation (API.Conversation entity) {
		Object (conversation: entity, status: entity.last_status);
		conversation.bind_property ("unread", this.indicator, "icon_name", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			if (src.get_boolean()) {
				target.set_string ("tuba-mark-important-symbolic");
				this.indicator.remove_css_class("dim-label");
			} else {
				target.set_string ("tuba-mail-symbolic");
				this.indicator.add_css_class("dim-label");
			}
			return true;
		});
		// this.indicators.child_set_property (this.indicator, "position", 2);
		this.actions.destroy ();
	}

	public new string title_text {
		owned get {
			var label = "";
			foreach (API.Account account in conversation.accounts) {
				label += account.display_name;
				if (conversation.accounts.last () != account)
					label += ", ";
			}
			return label;
		}
	}

	public new string subtitle_text {
		owned get {
			var label = "";
			foreach (API.Account account in conversation.accounts) {
				label += account.handle + " ";
			}
			return label;
		}
	}

	public new string? avatar_url {
		owned get {
			if (conversation.accounts.size > 1)
				return null;
			else
				return conversation.accounts.get (0).avatar;
		}
	}

	public override void on_open () {
		conversation.open ();
	}

}
