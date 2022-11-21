using Gtk;
using Gdk;

public class Tooth.Views.Notifications : Views.Timeline, AccountHolder, Streamable {

	protected InstanceAccount? last_account = null;

	public Notifications () {
		Object (
			url: "/api/v1/notifications",
			label: _("Notifications"),
			icon: "tooth-bell-symbolic",
			badge_number: 0,
			needs_attention: false
		);
		accepts = typeof (API.Notification);
	}

	public override void on_account_changed (InstanceAccount? acc) {
		base.on_account_changed (acc);

		if (last_account != null) {
			last_account.notification_inhibitors.remove (this);
			acc.stream_event[InstanceAccount.EVENT_NOTIFICATION].disconnect (on_new_post);
			//  acc.stream_event[InstanceAccount.EVENT_NOTIFICATION].disconnect (on_new_post_badge);
		}

		last_account = acc;
		acc.stream_event[InstanceAccount.EVENT_NOTIFICATION].connect (on_new_post);
		//  acc.stream_event[InstanceAccount.EVENT_NOTIFICATION].connect (on_new_post_badge);
		acc.bind_property ("unread_count", this, "badge_number", BindingFlags.SYNC_CREATE);
		acc.bind_property ("has_unread", this, "needs_attention", BindingFlags.SYNC_CREATE);
		//  acc.check_notifications ();
		//  acc.init_notifications();
	}

	//  public virtual void on_new_post_badge (Streamable.Event ev) {
	//  	needs_attention = true;
	//  }

	public override void on_shown () {
		base.on_shown ();
		if (account != null) {
			if (!account.notification_inhibitors.contains (this))
				account.notification_inhibitors.add (this);

			account.read_notifications (account.last_received_id > account.last_read_id ? account.last_received_id : account.last_read_id);
		}
	}
	public override void on_hidden () {
		base.on_hidden ();
		if (account != null) {
			if (account.notification_inhibitors.contains (this))
				account.notification_inhibitors.remove (this);
		}
	}

}
