public class Tuba.API.Push : Entity {
	public string endpoint { get; set; }
	public string server_key { get; set; }

	public class Payload : Entity {
		public int64 notification_id { get; set; }
		public string notification_type { get; set; }
		public string icon { get; set; }
		public string title { get; set; }
		public string? body { get; set; default = null; }
	}
}
