public class Tuba.API.BookWyrm : Entity, Widgetizable {
	public string id { get; set; default=""; }
	public string openlibraryKey { get; set; default=""; }
	public string title { get; set; default=""; }
	public string description { get; set; default=""; }
	public string isbn13 { get; set; default=""; }
	public string publishedDate { get; set; default=""; }
	public API.BookWyrmCover? cover { get; set; default=null; }
	public Gee.ArrayList<string>? authors { get; set; default=null; }

	public static BookWyrm from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.BookWyrm), node) as API.BookWyrm;
	}

    public override Gtk.Widget to_widget () {
        return new Widgets.BookWyrmPage (this);
    }

    public override void open () {}
}
