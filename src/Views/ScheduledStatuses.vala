public class Tuba.Views.ScheduledStatuses : Views.Timeline {
	construct {
		url = "/api/v1/scheduled_statuses";
		label = _("Scheduled Posts");
		icon = "tuba-bookmarks-symbolic"; // TODO?
		empty_state_title = _("No Scheduled Posts");
		accepts = typeof (API.ScheduledStatus);
	}

	public override Gtk.Widget on_create_model_widget (Object obj) {
		var widget = base.on_create_model_widget (obj);
		var widget_scheduled = widget as Widgets.ScheduledStatus;

		if (widget_scheduled != null) widget_scheduled.deleted.connect (on_deleted_scheduled);

		return widget;
	}

	private void on_deleted_scheduled (string scheduled_status_id) {
		for (uint i = 0; i < model.get_n_items (); i++) {
			var status_obj = (API.ScheduledStatus) model.get_item (i);
			if (status_obj.id == scheduled_status_id) {
				model.remove (i);
				break;
			}
		}
	}

	public override bool should_hide (Entity entity) {
		var scheduled_entity = entity as API.ScheduledStatus;
		return scheduled_entity != null && new GLib.DateTime.from_iso8601 (scheduled_entity.scheduled_at, null).get_year () > API.ScheduledStatus.DRAFT_YEAR;
	}
}
