public class Tuba.Views.NotificationRequests : Views.Timeline {
	public NotificationRequests () {
		Object (
			url: "/api/v1/notifications/requests",
			label: _("Filtered Notifications"),
			icon: "tuba-bell-outline-symbolic",
			empty_state_title: _("No Filtered Notifications"),
			batch_size_min: 20
		);
	}

	construct {
		accepts = typeof (API.NotificationFilter.Request);
	}

	public override Gtk.Widget on_create_model_widget (Object obj) {
		var widget = base.on_create_model_widget (obj);
		var widget_notification_req = widget as Widgets.NotificationRequest;

		if (widget_notification_req != null) {
			widget_notification_req.dismissed.connect (on_response);
			widget_notification_req.accepted.connect (on_response);
		}

		return widget;
	}

	private void on_response (Widgets.NotificationRequest wdg, RequestV2 req, API.NotificationFilter.Request api_req) {
		wdg.btns_box.sensitive = false;
		on_response_real.begin (wdg, req, api_req);
	}

	private async void on_response_real (Widgets.NotificationRequest wdg, RequestV2 req, API.NotificationFilter.Request api_req) {
		try {
			yield req.exec (null);

			uint indx;
			var found = model.find (api_req, out indx);
			if (found) {
				model.remove (indx);

				if (accounts.active.filtered_notifications_count > 0) {
					int to_remove = int.parse (api_req.notifications_count);
					if (to_remove < 1) to_remove = 1;

					accounts.active.filtered_notifications_count -= to_remove;
				}
			} else {
				wdg.btns_box.sensitive = true;
			}
		} catch (Error e) {
			wdg.btns_box.sensitive = true;
		}
	}

	public override void on_content_item_activated (Gtk.ListBoxRow row) {
		((Widgets.NotificationRequest) row).open ();
	}
}
