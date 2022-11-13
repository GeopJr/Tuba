using Gtk;

public class Tooth.API.List : Entity, Widgetizable {

    public string id { get; set; }
    public string title { get; set; }

	public static List from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.List), node) as API.List;
	}

    public override Gtk.Widget to_widget () {
        return new Views.Lists.Row (this);
    }

}
