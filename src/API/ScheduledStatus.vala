public class Tuba.API.ScheduledStatus : Entity, Widgetizable {
	// NOTE: Don't forget to update in the year 3000
	public const int DRAFT_YEAR = 2000 + 3000;

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
		public bool sensitive { get; set; default=false; }
		public string? spoiler_text { get; set; default = null; }
		public string visibility { get; set; }
		public string? language { get; set; default = null; }
		public string? in_reply_to_id { get; set; default = null; }
		public bool local_only { get; set; default = false; }

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

	public static ScheduledStatus from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.ScheduledStatus), node) as API.ScheduledStatus;
	}

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "media-attachments":
				return typeof (API.Attachment);
		}

		return base.deserialize_array_type (prop);
	}

	public override Gtk.Widget to_widget () {
		return new Widgets.ScheduledStatus (this);
	}
}
