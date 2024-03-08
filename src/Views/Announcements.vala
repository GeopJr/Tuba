public class Tuba.Views.Announcements : Views.Timeline {
	public bool dismiss_all_announcements { get; set; default=false; }
	construct {
		url = "/api/v1/announcements?with_dismissed=true";
		label = _("Announcements");
		icon = "tuba-lightbulb-symbolic";
		accepts = typeof (API.Announcement);
		empty_state_title = _("No Announcements");
	}

	public void dismiss_all () {
		// Why isn't there a dismiss all endpoint?
		for (uint i = 0; i < model.get_n_items (); i++) {
			var announcement_obj = (API.Announcement) model.get_item (i);
			if (announcement_obj != null && !announcement_obj.read) {
				announcement_obj.open ();
			}
		}
	}

	public override void on_content_changed () {
		if (dismiss_all_announcements)
			dismiss_all ();
		base.on_content_changed ();
	}
}
