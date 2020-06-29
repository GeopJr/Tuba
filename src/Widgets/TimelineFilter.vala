using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/timeline_filter.ui")]
public class Tootle.Widgets.TimelineFilter : MenuButton {

	[GtkChild]
	public Label title;

	[GtkChild]
	public RadioButton radio_source;

	[GtkChild]
	public Revealer post_filter;
	[GtkChild]
	public RadioButton radio_post_filter;
	[GtkChild]
	public RadioButton radio_post_only_media;

	public string source { get; set; }

	construct {
		radio_source.bind_property ("active", post_filter, "reveal-child", BindingFlags.SYNC_CREATE);
	}

	public TimelineFilter.with_profile (Views.Profile view) {
		radio_source.get_group ().@foreach (w => {
			w.toggled.connect (() => {
				if (w.active) {
					source = w.name;
					on_changed (view);
				}
			});
		});
		radio_post_filter.get_group ().@foreach (w => {
			w.toggled.connect (() => {
				if (w.active)
					on_changed (view);
			});
		});
	}

	void on_changed (Views.Profile view) {
		var entity = typeof (API.Status);
		if (source != "statuses")
			entity = typeof (API.Account);

		view.exclude_replies = radio_post_filter.active;
		view.only_media = radio_post_only_media.active;

		view.page_next = view.page_prev = null;
		view.url = @"/api/v1/accounts/$(view.profile.id)/$source";
		view.accepts = entity;
		view.on_refresh ();
	}

}
