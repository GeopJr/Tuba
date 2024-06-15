public class Tuba.API.Admin.EmailDomainBlock : Entity, BasicWidgetizable {
	public class History : Entity {
		public string accounts { get; set; }
		public string uses { get; set; }
	}

	public string id { get; set; }
	public string domain { get; set; }
	public Gee.ArrayList<History>? history { get; set; default=null; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "history":
				return typeof (History);
		}

		return base.deserialize_array_type (prop);
	}

	public override Gtk.Widget to_widget () {
		return new Widgets.Admin.EmailDomainBlock (this);
	}
}
