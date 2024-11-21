public class Tuba.Views.ScheduledStatuses : Views.Timeline {
	construct {
		url = "/api/v1/scheduled_statuses";
		label = _("Scheduled Posts");
		icon = "tuba-bookmarks-symbolic"; // TODO?
		empty_state_title = _("No Scheduled Posts");
		accepts = typeof (API.ScheduledStatus);
	}
	public override bool should_hide (Entity entity) {
		var scheduled_entity = entity as API.ScheduledStatus;
		return scheduled_entity != null && new GLib.DateTime.from_iso8601 (scheduled_entity.scheduled_at, null).get_year () > API.ScheduledStatus.DRAFT_YEAR;
	}
}
