public class Tuba.Views.Announcements : Views.Timeline {
    public Announcements () {
        Object (
			url: "/api/v1/announcements?with_dismissed=true",
			label: _("Announcements"),
			icon: "tuba-lightbulb-symbolic"
		);
        accepts = typeof (API.Announcement);
    }
}
