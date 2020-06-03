public class Tootle.API.Conversation : GLib.Object, Json.Serializable, Widgetizable  {

	public string id { get; construct set; }
	public bool unread { get; set; default = false; }

	public Conversation () {
		GLib.Object ();
	}

}
