public class Tuba.Views.ScheduledStatuses : Views.Timeline {
	construct {
		url = "/api/v1/scheduled_statuses";
		label = _("Scheduled Posts");
		icon = "tuba-bookmarks-symbolic"; // TODO?
		empty_state_title = _("No Scheduled Posts");
		accepts = typeof (API.ScheduledStatus);
	}
}
