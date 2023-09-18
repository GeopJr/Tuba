public class Tuba.API.Pleroma.Instance : Entity {
	public class Metadata : Entity {
		public class FieldLimits : Entity {
			public int64 max_fields { get; set; default = 10; }
			public int64 name_length { get; set; default = 512; }
			public int64 value_length { get; set; default = 2048; }
		}

		public FieldLimits? fields_limits { get; set; default = null; }
		public string[]? post_formats { get; set; default = null; }
	}

	public Metadata? metadata { get; set; default = null; }
}
