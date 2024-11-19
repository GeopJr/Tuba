public class Tuba.API.ScheduledStatus : Entity, Widgetizable {
	public class Params : Entity {
		public class Poll : Entity {
			public Gee.ArrayList<string> options { get; set; default=new Gee.ArrayList <string> (); }
			public int64 expires_in { get; set; default=0; }
			public bool multiple { get; set; default=false; }
			public bool hide_totals { get; set; default=false; }

			public override Type deserialize_array_type (string prop) {
				switch (prop) {
					case "options":
						return Type.STRING;
				}

				return base.deserialize_array_type (prop);
			}
		}

		public string text { get; set; }
		public Poll? poll { get; set; }
		public Gee.ArrayList<string>? media_ids { get; set; }
		public bool? sensitive { get; set; default=false; }
		public string? spoiler_text { get; set; }
		public string visibility { get; set; }
		public string? language { get; set; }
		public string? in_reply_to_id { get; set; }

		public override Type deserialize_array_type (string prop) {
			switch (prop) {
				case "media-ids":
					return Type.STRING;
			}

			return base.deserialize_array_type (prop);
		}
	}

	public string id { get; set; }
	public string scheduled_at { get; set; }
	public Gee.ArrayList<API.Attachment>? media_attachments { get; set; default = null; }
	public Params? props { get; set; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "media-attachments":
				return typeof (API.Attachment);
		}

		return base.deserialize_array_type (prop);
	}

	public override Gtk.Widget to_widget () {
		API.Poll? poll = null;
		if (this.props.poll != null) {
			poll = new API.Poll ("0") {
				multiple = this.props.poll.multiple,
				options = new Gee.ArrayList<API.PollOption> ()
			};

			foreach (string poll_option in this.props.poll.options) {
				poll.options.add (new API.PollOption () {
					title = poll_option,
					votes_count = 0
				});
			}
		}

		var status = new API.Status.empty () {
			id = this.id,
			account = accounts.active,
			spoiler_text = this.props.spoiler_text,
			content = this.props.text,
			sensitive = this.props.sensitive,
			visibility = this.props.visibility,
			media_attachments = this.media_attachments,
			tuba_spoiler_revealed = true,
			tuba_scheduled = true,
			poll = poll,
			created_at = this.scheduled_at
		};

		if (this.props.language != null) status.language = this.props.language;

		var widg = new Widgets.Status (status);
		widg.actions.visible = false;
		widg.activatable = false;

		return widg;
	}
}
