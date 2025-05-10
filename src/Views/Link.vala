public class Tuba.Views.Link : Views.Timeline {
	public Link (string link) {
		Object (
			url: @"/api/v1/timelines/link?url=$(Uri.escape_string (link))",
			label: link,
			icon: "tuba-globe-symbolic"
		);
	}
}
