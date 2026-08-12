public class Tuba.API.Announcement : Entity, Widgetizable {
	public string id { get; set; }
	public string content { get; set; }
	public bool published { get; set; default=true; }
	public string published_at { get; set; }
	public string updated_at { get; set; }
	public bool read { get; set; default=true; }
	public Gee.ArrayList<API.Emoji>? emojis { get; set; }
	public Gee.ArrayList<API.EmojiReaction>? reactions { get; set; default = null; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "reactions":
				return typeof (API.EmojiReaction);
			case "emojis":
				return typeof (API.Emoji);
		}

		return base.deserialize_array_type (prop);
	}

	public Gee.HashMap<string, string>? emojis_map {
		owned get {
			return gen_emojis_map ();
		}
	}

	private Gee.HashMap<string, string>? gen_emojis_map () {
		var res = new Gee.HashMap<string, string> ();
		if (emojis != null && emojis.size > 0) {
			emojis.@foreach (e => {
				res.set (e.shortcode, e.url);
				return true;
			});
		}

		return res;
	}

	public override Gtk.Widget to_widget () {
		return new Widgets.Announcement (this);
	}

	public override void open () {
		if (this.read) return;
		open_real.begin ();
	}

	private async void open_real () {
		var req = new RequestV2 (@"/api/v1/announcements/$(this.id)/dismiss", POST) { account = accounts.active };

		try {
			yield req.exec (null);
			this.read = true;
		} catch (GLib.IOError.CANCELLED e) {
			debug ("Message is cancelled.");
		} catch (Error e) {
			warning (@"Error while dismissing announcement: $(e.code) $(e.message)");

			var dlg = app.inform (_("Error"), e.message);
			dlg.present (app.main_window);
		}
	}
}
