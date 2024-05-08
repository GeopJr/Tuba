public class Tuba.API.Translation : Entity {
	public class Poll : Entity {
		public class Option : Entity {
			public string title { get; set; default = ""; }
		}
		public string id { get; set; default = ""; }
		public Gee.ArrayList<Option>? options { get; set; default = null; }
	}

	public class Attachment : Entity {
		public string id { get; set; default = ""; }
		public string options { get; set; default = ""; }
	}

	public string content { get; set; default = ""; }
	public string spoiler_text { get; set; default = ""; }
	public Poll? poll { get; set; default = null; }
	public Gee.ArrayList<Attachment>? media_attachments { get; set; default = null; }
	public string detected_source_language { get; set; default = ""; }
	public string provider { get; set; default = ""; }

	public static Translation from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Translation), node) as API.Translation;
	}
}
