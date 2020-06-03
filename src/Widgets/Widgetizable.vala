public interface Tootle.Widgetizable : GLib.Object {

	public virtual Gtk.Widget to_widget () throws Oopsie {
		throw new Tootle.Oopsie.INTERNAL ("Widgetizable didn't provide a Widget!");
	}

}
