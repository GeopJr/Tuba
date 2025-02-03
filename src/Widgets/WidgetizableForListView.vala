public interface Tuba.WidgetizableForListView : GLib.Object {
	public virtual Gtk.Widget to_widget () throws Oopsie {
		throw new Tuba.Oopsie.INTERNAL ("Widgetizable didn't provide a Widget!");
	}

	public virtual void open () {
		warning ("Widgetizable didn't provide a way to open it!");
	}

	public virtual void resolve_open (InstanceAccount account) {
		this.open ();
	}

	public virtual void fill_widget_with_content (Gtk.Widget widget) throws Oopsie {
		throw new Tuba.Oopsie.INTERNAL ("Widgetizable didn't fill widget with content!");
	}
}
