using Gtk;

public class Tootle.Widgets.Conversation : Widgets.Status {

	public API.Conversation conversation { get; construct set; }

	public Conversation (API.Conversation entity) {
		Object (conversation: entity, status: entity.last_status);
		conversation.bind_property ("unread", this.indicator, "visible", BindingFlags.SYNC_CREATE);
		// this.indicators.child_set_property (this.indicator, "position", 2);
		this.indicator.opacity = 1;
		this.indicator.icon_name = "software-update-urgent-symbolic";
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
