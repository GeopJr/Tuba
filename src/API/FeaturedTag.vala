public class Tuba.API.FeaturedTag : Entity, Widgetizable {
	public string name { get; set; }
	public string url { get; set; }
	public string last_status_at { get; set; default = ""; }
	public string statuses_count { get; set; default = "0"; }

	public static FeaturedTag from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.FeaturedTag), node) as API.FeaturedTag;
	}

	public override void open () {
		#if USE_LISTVIEW
			app.main_window.open_view (new Views.Hashtag (name, null, Path.get_basename (url)));
		#endif
	}

	public override Gtk.Widget to_widget () {
		var w = new Adw.ActionRow () {
			title = @"#$name",
			activatable = true
		};

		w.add_suffix (
			new Gtk.Label (GLib.ngettext (
				"%s Post",
				"%s Posts",
				(ulong) this.statuses_count.to_int ()
			).printf (this.statuses_count)) {
				ellipsize = END,
				// translators: tooltip on featured hashtags on profiles on a number that
				//				shows the amount of posts that use said hashtag
				tooltip_text = _("Posts Including this Hashtag")
			}
		);

		if (statuses_count != "0" && last_status_at != "") {
			// translators: subtitle on featured hashtags on profiles. The variable is a string date.
			w.subtitle = _("Last post on %s").printf (this.last_status_at);
		}

		#if !USE_LISTVIEW
			w.activated.connect (on_activated);
		#endif

		return w;
	}

	#if !USE_LISTVIEW
		protected void on_activated () {
			app.main_window.open_view (new Views.Hashtag (name, null, Path.get_basename (url)));
		}
	#endif
}
