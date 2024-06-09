public class Tuba.API.Admin.Account : Entity, BasicWidgetizable {
	public class IPAddress : Entity {
		public string ip { get; set; }
	}

	public string id { get; set; }
	public string username { get; set; }
	public string? domain { get; set; default=null; }
	public string email { get; set; }
	public string? ip { get; set; default=null; }
	public Gee.ArrayList<IPAddress>? ips { get; set; default=null; }
	public bool confirmed { get; set; default = true; }
	public bool suspended { get; set; default = false; }
	public bool disabled { get; set; default = false; }
	public bool silenced { get; set; default = false; }
	public bool approved { get; set; default = true; }
	public string? invite_request { get; set; default=null; }
	public API.AccountRole? role { get; set; }
	public API.Account account { get; set; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "ips":
				return typeof (IPAddress);
		}

		return base.deserialize_array_type (prop);
	}

	public override Gtk.Widget to_widget () {
		return new Widgets.Admin.AccountRow (this);
	}
}
