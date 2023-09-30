public class Tuba.API.AccountRole : Entity {
	public string id { get; set; default = ""; }
	public string name { get; set; default = ""; }
    // Ignore for now
	//  public string color { get; set; default = ""; }

    public Gtk.Widget to_widget () {
		return new Gtk.Label (name) {
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            css_classes = { "profile-role", "profile-role-border-radius" }
        };
	}
}
