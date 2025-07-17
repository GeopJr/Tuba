public class Tuba.API.Suggestion : Entity, Widgetizable {
	public API.Account account { get; set; }

	public override void open () {
		account.open ();
	}

	public override Gtk.Widget to_widget () {
		return account.to_widget ();
	}
}
