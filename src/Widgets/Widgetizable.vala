public interface Tuba.BasicWidgetizable : GLib.Object {
	public virtual Gtk.Widget to_widget () {
		assert_not_reached ();
	}
}

public interface Tuba.Widgetizable : GLib.Object {
	public virtual Gtk.Widget to_widget () {
		assert_not_reached ();
	}

	public virtual void open () {
		warning ("Widgetizable didn't provide a way to open it!");
	}

	public virtual void resolve_open (InstanceAccount account) {
		this.open ();
	}
}
