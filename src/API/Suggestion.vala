public class Tuba.API.Suggestion : Entity, Widgetizable {
    public API.Account account { get; set; }

	public override Gtk.Widget to_widget () {
        try {
            return account.to_widget ();
        } catch {
            return new Gtk.Label (_("Account not found")) {
				margin_top = 16,
				margin_bottom = 16,
				margin_start = 16,
				margin_end = 16,
                wrap = true
			};
        }
	}
}
