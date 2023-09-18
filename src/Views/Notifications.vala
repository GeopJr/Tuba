public class Tuba.Views.Notifications : Views.Timeline, AccountHolder, Streamable {
	protected InstanceAccount? last_account = null;
	private Binding badge_number_binding;

	construct {
        url = "/api/v1/notifications";
        label = _("Notifications");
        icon = "tuba-bell-outline-symbolic";
        accepts = typeof (API.Notification);
		badge_number = 0;
		needs_attention = false;

		stream_event[InstanceAccount.EVENT_NOTIFICATION].connect (on_new_post);
    }

	~Notifications () {
		warning ("Destroying Notifications");
		stream_event[InstanceAccount.EVENT_NOTIFICATION].disconnect (on_new_post);
		badge_number_binding.unbind ();
	}

	public override void on_account_changed (InstanceAccount? acc) {
		base.on_account_changed (acc);

		if (badge_number_binding != null)
			badge_number_binding.unbind ();

		badge_number_binding = accounts.active.bind_property (
			"unread-count",
			this,
			"badge-number",
			BindingFlags.SYNC_CREATE,
			(b, src, ref target) => {
				var unread_count = src.get_int ();
				target.set_int (unread_count);
				this.needs_attention = unread_count > 0;
				Tuba.Mastodon.Account.PLACE_NOTIFICATIONS.badge = unread_count;

				return true;
			}
		);
	}

	public override void on_shown () {
		base.on_shown ();
		if (account != null) {
			account.read_notifications (
				account.last_received_id > account.last_read_id
					? account.last_received_id
					: account.last_read_id
			);
		}
	}

	public override void on_hidden () {
		base.on_hidden ();
		if (account != null) {
			account.unread_count = 0;
		}
	}

	public override string? get_stream_url () {
		return account != null
			? @"$(account.instance)/api/v1/streaming/?stream=user:notification&access_token=$(account.access_token)"
			: null;
    }
}
