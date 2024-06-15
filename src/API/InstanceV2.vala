public class Tuba.API.InstanceV2 : Entity {
	public class Configuration : Entity {
		public class Translation : Entity {
			public bool enabled { get; set; default = false; }
		}
		public Translation translation { get; set; default = null; }
	}

	public Configuration configuration { get; set; default = null; }

	public static InstanceV2 from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.InstanceV2), node) as API.InstanceV2;
	}
}
