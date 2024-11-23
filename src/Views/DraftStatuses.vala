public class Tuba.Views.DraftStatuses : Views.ScheduledStatuses {
	construct {
		label = _("Draft Posts");
		icon = "tuba-bookmarks-symbolic"; // TODO?
		empty_state_title = _("No Draft Posts");
	}

	public override Gtk.Widget on_create_model_widget (Object obj) {
		var widget = base.on_create_model_widget (obj);
		var widget_scheduled = widget as Widgets.ScheduledStatus;

		if (widget_scheduled != null) widget_scheduled.draft = true;

		return widget;
	}

	public override bool should_hide (Entity entity) {
		var scheduled_entity = entity as API.ScheduledStatus;
		return scheduled_entity != null && new GLib.DateTime.from_iso8601 (scheduled_entity.scheduled_at, null).get_year () <= API.ScheduledStatus.DRAFT_YEAR;
	}
}
