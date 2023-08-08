public class Tuba.API.Notification : Entity, Widgetizable {

    public string id { get; set; }
    public API.Account account { get; set; }
    public string? kind { get; set; default = null; }
    public API.Status? status { get; set; default = null; }

    public override Gtk.Widget to_widget () {
        return new Widgets.Notification (this);
    }

	public virtual GLib.Notification to_toast (InstanceAccount issuer) {
        bool should_show_buttons = issuer == accounts.active;

		string descr;
		string descr_url;
		issuer.describe_kind (kind, null, out descr, account, out descr_url);

		var toast = new GLib.Notification ( HtmlUtils.remove_tags (descr) );
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
                            new Variant.string (status.uri)
                        );
                    }
                    break;
                case InstanceAccount.KIND_FOLLOW:
                    toast.add_button_with_target_value (
                        _("Remove from Followers"),
                        "app.remove-from-followers",
                        new Variant.string (account.id)
                    );
                    toast.add_button_with_target_value (
                        _("Follow Back"),
                        "app.follow-back",
                        new Variant.string (account.id)
                    );
                    break;
                case InstanceAccount.KIND_FOLLOW_REQUEST:
                    toast.add_button_with_target_value (
                        _("Decline"),
                        "app.answer-follow-request",
                        new Variant.tuple ({account.id, false})
                    );
                    toast.add_button_with_target_value (
                        _("Accept"),
                        "app.answer-follow-request",
                        new Variant.tuple ({account.id, true})
                    );
                    break;
            }
        }

        if (!Tuba.is_flatpak) {
            var icon_file = GLib.File.new_for_uri (account.avatar);
            var icon = new FileIcon (icon_file);
            toast.set_icon (icon);
        }

		return toast;
	}
}
