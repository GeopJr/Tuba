public class Tuba.Views.ContentBase : Views.Base {

	public GLib.ListStore model;
	protected Gtk.ListView content;
	private bool bottom_reached_locked = false;
	//  protected signal void reached_close_to_top ();

	public bool empty {
		get { return model.get_n_items () <= 0; }
	}

	construct {
		Gtk.SignalListItemFactory signallistitemfactory = new Gtk.SignalListItemFactory ();
		signallistitemfactory.bind.connect (bind_listitem_cb);

		model = new GLib.ListStore (typeof (Widgetizable));
		content = new Gtk.ListView (new Gtk.NoSelection (model), signallistitemfactory) {
			css_classes = { "content", "background" },
			single_click_activate = true
		};
		content_box.child = content;
		content.activate.connect (on_content_item_activated);

		scrolled.vadjustment.value_changed.connect (on_scrolled_vadjustment_value_change);
	}
	~ContentBase () {
		debug ("Destroying ContentBase");
	}

	protected virtual void on_scrolled_vadjustment_value_change () {
		if (
			!bottom_reached_locked
			&& scrolled.vadjustment.value > scrolled.vadjustment.upper - scrolled.vadjustment.page_size * 2
		) {
			bottom_reached_locked = true;
			on_bottom_reached ();
		}

		var is_close_to_top = scrolled.vadjustment.value <= 1000;
		scroll_to_top_rev.reveal_child = !is_close_to_top
			&& scrolled.vadjustment.value + scrolled.vadjustment.page_size + 100 < scrolled.vadjustment.upper;

		//  if (is_close_to_top) reached_close_to_top ();
	}

	protected virtual void bind_listitem_cb (GLib.Object item) {
		((Gtk.ListItem) item).child = on_create_model_widget (((Gtk.ListItem) item).item);

		var gtklistitemwidget = ((Gtk.ListItem) item).child.get_parent ();
		if (gtklistitemwidget != null) {
			gtklistitemwidget.add_css_class ("card");
			gtklistitemwidget.add_css_class ("card-spacing");
			gtklistitemwidget.focusable = true;

			// Thread lines overflow slightly
			gtklistitemwidget.overflow = Gtk.Overflow.HIDDEN;
		}
	}

	public override void dispose () {
		base.dispose ();
	}

	public override void clear () {
		base.clear ();
		model.remove_all ();
	}

	protected void clear_all_but_first () {
		base.clear ();

		if (model.n_items > 1)
			model.splice (1, model.n_items - 1, {});
	}

	public override void on_content_changed () {
		if (empty) {
			base_status = new StatusMessage ();
		}
		else {
			base_status = null;
		}
	}


	public virtual Gtk.Widget on_create_model_widget (Object obj) {
		var obj_widgetable = obj as Widgetizable;
		if (obj_widgetable == null)
			Process.exit (0);
		try {
			return obj_widgetable.to_widget ();
		} catch (Oopsie e) {
			warning (@"Error on_create_model_widget: $(e.message)");
			Process.exit (0);
		}
	}

	public virtual void on_bottom_reached () {
		uint timeout = 0;
		timeout = Timeout.add (1000, () => {
			bottom_reached_locked = false;
			GLib.Source.remove (timeout);

			return true;
		}, Priority.LOW);
	}

	public virtual void on_content_item_activated (uint pos) {
		((Widgetizable) ((ListModel) content.model).get_item (pos)).open ();
	}
}
