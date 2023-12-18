public class Tuba.API.Notification : Entity, Widgetizable {

	public string id { get; set; }
	public API.Account account { get; set; }
	public string? kind { get; set; default = null; }
	public API.Status? status { get; set; default = null; }

	public override void open () {
		if (status != null) {
			status.open ();
		} else {
			account.open ();
		}
	}

	public override Gtk.Widget to_widget () {
		switch (kind) {
			case InstanceAccount.KIND_FOLLOW:
			case InstanceAccount.KIND_FOLLOW_REQUEST:
				return new Widgets.Account (this.account);
			default:
				return new Widgets.Notification (this);
		}
	}

	public virtual async GLib.Notification to_toast (InstanceAccount issuer, int others = 0) {
		Tuba.InstanceAccount.Kind res_kind;
		bool should_show_buttons = issuer == accounts.active;

		var kind_actor_name = account.display_name;
		if (others > 0) {
			//  translators: <user> (& <amount> others) <actions>
			//               for example: GeopJr (& 10 others) mentioned you
			kind_actor_name = _("%s (& %d others)").printf (account.display_name, others);
		}

		issuer.describe_kind (kind, out res_kind, kind_actor_name);
		var toast = new GLib.Notification (res_kind.description);
		if (status != null) {
			var body = "";
			body += HtmlUtils.remove_tags (status.content);
			toast.set_body (body);
		}

		if (should_show_buttons) {
			toast.set_default_action_and_target_value (
				"app.open-status-url",
				new Variant.string (
					status?.url ?? account.url
				)
			);

			switch (kind) {
				case InstanceAccount.KIND_MENTION:
					if (status != null) {
						toast.add_button_with_target_value (
							_("Reply…"),
							"app.reply-to-status-uri",
							new Variant.tuple ({accounts.active.id, status.uri})
						);
					}
					break;
				case InstanceAccount.KIND_FOLLOW:
					toast.add_button_with_target_value (
						_("Remove from Followers"),
						"app.remove-from-followers",
						new Variant.tuple ({accounts.active.id, account.id})
					);
					toast.add_button_with_target_value (
						_("Follow Back"),
						"app.follow-back",
						new Variant.tuple ({accounts.active.id, account.id})
					);
					break;
				case InstanceAccount.KIND_FOLLOW_REQUEST:
					toast.add_button_with_target_value (
						_("Decline"),
						"app.answer-follow-request",
						new Variant.tuple ({accounts.active.id, account.id, false})
					);
					toast.add_button_with_target_value (
						_("Accept"),
						"app.answer-follow-request",
						new Variant.tuple ({accounts.active.id, account.id, true})
					);
					break;
			}
		}

		Icon? icon = null;
		if (Tuba.is_flatpak) {
			Bytes avatar_bytes = yield Tuba.Helper.Image.request_bytes (account.avatar);
			if (avatar_bytes != null)
				icon = new BytesIcon (avatar_bytes);
		} else {
			var icon_file = GLib.File.new_for_uri (account.avatar);
			icon = new FileIcon (icon_file);
		}

		if (icon != null)
			toast.set_icon (icon);

		return toast;
	}
}
