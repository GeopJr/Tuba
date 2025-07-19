public class Tuba.API.Nodeinfo : Entity {
	public class V20 : Entity {
		public class Software : Entity {
			public string? name { get; set; default = null; }
		}

		public Software software { get; set; default = null; }
	}

	public class Link : Entity {
		public string? rel { get; set; default = null; }
		public string? href { get; set; default = null; }
	}

	public Gee.ArrayList<Link>? links { get; set; default = null; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "links":
				return typeof (Link);
		}

		return base.deserialize_array_type (prop);
	}
}
