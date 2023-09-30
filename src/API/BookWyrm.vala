public class Tuba.API.BookWyrm : Entity, Widgetizable {
	public string id { get; set; default=""; }
	public string openlibraryKey { get; set; default=""; } // vala-lint=naming-convention
	public string title { get; set; default=""; }
	public string description { get; set; default=""; }
	public string isbn13 { get; set; default=""; }
	public string publishedDate { get; set; default=""; } // vala-lint=naming-convention
	public API.BookWyrmCover? cover { get; set; default=null; }
	public Gee.ArrayList<string>? authors { get; set; default=null; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "authors":
				return Type.STRING;
		}

		return base.deserialize_array_type (prop);
	}

	public static BookWyrm from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.BookWyrm), node) as API.BookWyrm;
	}

    public override Gtk.Widget to_widget () {
        return new Widgets.BookWyrmPage (this);
    }

    public override void open () {}
}
