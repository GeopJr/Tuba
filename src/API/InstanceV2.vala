public class Tuba.API.InstanceV2 : Entity {
	public class Configuration : Entity {
		public class Translation : Entity {
			public bool enabled { get; set; default = false; }
		}
		public Translation translation { get; set; default = null; }
	}

	public class APIVersions : Entity {
		public int8 mastodon { get; set; default = 0; }
		public int8 chuckya { get; set; default = 0; }

		public bool tuba_same (APIVersions new_val) {
			return new_val.mastodon == this.mastodon
				&& new_val.chuckya == this.chuckya;
		}
	}

	public Configuration configuration { get; set; default = null; }
	public APIVersions? api_versions { get; set; default = null; }

	public static InstanceV2 from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.InstanceV2), node) as API.InstanceV2;
	}
}
