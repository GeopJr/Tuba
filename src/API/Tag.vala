using Gtk;

public class Tooth.API.Tag : Entity, Widgetizable {

    public string name { get; set; }
    public string url { get; set; }

	public static Tag from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Tag), node) as API.Tag;
	}

	public override Widget to_widget () {
		var encoded = Soup.URI.encode (name, null);
		var w = new Widgets.RichLabel (@"<a href=\"$(accounts.active.instance)/tags/$encoded\">#$name</a>");
		w.halign = Align.START;
		w.show ();
		return w;
	}

}
