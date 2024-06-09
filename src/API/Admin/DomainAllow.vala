public class Tuba.API.Admin.DomainAllow : Entity, BasicWidgetizable {
	public string id { get; set; }
	public string domain { get; set; }

	public override Gtk.Widget to_widget () {
		return new Widgets.Admin.DomainAllow (this);
	}
}
