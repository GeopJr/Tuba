public class Tuba.API.InstanceV2 : Entity {
	public class Configuration : Entity {
		public class Translation : Entity {
			public bool enabled { get; set; default = false; }
		}
		public Translation translation { get; set; default = null; }
	}

	public class APIVersions : Entity {
		// Only include the APIs that require special cases
		// The fallback is Mastodon, but when activating an
		// account, we could theoretically write special
		// cases to re-guess and update it in future
		// additions.
		public enum BackendAPI {
			AKKOMA,
			PLEROMA,
			ICESHRIMP,
			GOTOSOCIAL,
			MASTODON;

			public static BackendAPI from_string (string backend_api) {
				switch (backend_api.down ()) {
					case "akkoma": return AKKOMA;
					case "pleroma": return PLEROMA;
					case "iceshrimp.net": return ICESHRIMP;
					case "gotosocial": return GOTOSOCIAL;
					default: return MASTODON;
				}
			}

			public string to_string () {
				switch (this) {
					case AKKOMA: return "Akkoma";
					case PLEROMA: return "Pleroma";
					case ICESHRIMP: return "Iceshrimp.NET";
					case GOTOSOCIAL: return "GoToSocial";
					default: return "Mastodon";
				}
			}
		}

		public int8 mastodon { get; set; default = 0; }
		public int8 chuckya { get; set; default = 0; }
		public int8 tuba_backend { get; set; default = 0; }

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
