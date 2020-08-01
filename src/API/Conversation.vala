public class Tootle.API.Conversation : Entity, Widgetizable {

	public string id { get; construct set; }
	public bool unread { get; set; default = false; }

}
