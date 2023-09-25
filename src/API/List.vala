public class Tuba.API.List : Entity, Widgetizable {
    public string id { get; set; }
    public string title { get; set; }
    public string? replies_policy { get; set; default = null; }
    public bool exclusive { get; set; default = false; }

	public static List from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.List), node) as API.List;
	}

    public override Gtk.Widget to_widget () {
        return new Views.Lists.Row (this);
    }

    public override void open () {
		app.main_window.open_view (new Views.List (this));
    }
}
