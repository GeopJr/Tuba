public class Tuba.Views.List : Views.Timeline {
	public API.List list { get; set; }

	public List (API.List l) {
		Object (
			uid: 1,
			url: @"/api/v1/timelines/list/$(l.id)",
			label: l.title,
			icon: "tuba-list-compact-symbolic",
			list: l
		);

		update_stream ();
	}

	public override string? get_stream_url () {
		if (list == null)
			return null;
		return account != null
			? @"$(account.instance)/api/v1/streaming?stream=list&list=$(list.id)&access_token=$(account.access_token)"
			: null;
	}
}
