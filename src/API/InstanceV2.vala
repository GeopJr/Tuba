public class Tuba.API.InstanceV2 : Entity {
	public class Configuration : Entity {
		public class Translation : Entity {
			public bool enabled { get; set; default = false; }
		}

		public class MediaAttachments : Entity {
			public int64 description_limit { get; set; default = 1500; }
		}

		public class Vapid : Entity {
			public string public_key { get; set; }
		}

		public class AccountsCharLimits : Entity {
			public int64 max_display_name_length { get; set; default = 40; }
			public int64 max_note_length { get; set; default = 500; }
			public int64 max_avatar_description_length { get; set; default = 150; }
			public int64 max_header_description_length { get; set; default = 150; }

			//  public int64 max_featured_tags { get; set; default = 10; }
			//  public int64 max_pinned_statuses { get; set; default = 5; }
			public int64 max_profile_fields { get; set; default = 4; }

			public int64 profile_field_name_limit { get; set; default = 255; }
			public int64 profile_field_value_limit { get; set; default = 255; }
		}

		public Translation translation { get; set; default = null; }
		public MediaAttachments media_attachments { get; set; default = null; }
		public Vapid vapid { get; set; default = null; }
		public AccountsCharLimits accounts { get; set; default = null; }
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
