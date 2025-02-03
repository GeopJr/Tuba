public class Tuba.Views.ContentBaseListView : Views.Base {

	protected Gtk.ListView content;
	protected signal void reached_close_to_top ();
	public GLib.ListStore model;
	private bool bottom_reached_locked = false;

	public bool empty {
		get { return model.get_n_items () <= 0; }
	}

	construct {
		model = new GLib.ListStore (typeof (WidgetizableForListView));

		Gtk.SignalListItemFactory signallistitemfactory = new Gtk.SignalListItemFactory ();
		signallistitemfactory.setup.connect (setup_listitem_cb);
		signallistitemfactory.bind.connect (bind_listitem_cb);

		content = new Gtk.ListView (new Gtk.NoSelection (model), signallistitemfactory) {
			css_classes = { "content", "background" },
			single_click_activate = true
		};

		content.activate.connect (on_content_item_activated);
		content_box.child = content;

		scrolled.vadjustment.value_changed.connect (on_scrolled_vadjustment_value_change);
		scroll_to_top_rev.bind_property ("child-revealed", scroll_to_top_rev, "visible", GLib.BindingFlags.SYNC_CREATE);
	}
	~ContentBaseListView () {
		debug ("Destroying ContentBaseListView");
	}

	protected virtual void on_scrolled_vadjustment_value_change () {
		if (
			!bottom_reached_locked
			&& scrolled.vadjustment.value > scrolled.vadjustment.upper - scrolled.vadjustment.page_size * 2
		) {
			bottom_reached_locked = true;
			on_bottom_reached ();
		}

		var is_close_to_top = scrolled.vadjustment.value <= 100;
		set_scroll_to_top_reveal_child (
			!is_close_to_top
			&& scrolled.vadjustment.value + scrolled.vadjustment.page_size + 100 < scrolled.vadjustment.upper
		);
	}

	protected void set_scroll_to_top_reveal_child (bool reveal) {
		if (reveal == scroll_to_top_rev.reveal_child) return;
		if (reveal) scroll_to_top_rev.visible = true;

		scroll_to_top_rev.reveal_child = reveal;
	}

	protected void setup_listitem_cb (GLib.Object item) {
		Gtk.ListItem i = (Gtk.ListItem) item;
		i.child = on_create_model_widget (i.item);

		var gtklistitemwidget = i.child.get_parent ();
		if (gtklistitemwidget != null) {
			gtklistitemwidget.add_css_class ("card");
			gtklistitemwidget.add_css_class ("card-spacing");
			gtklistitemwidget.focusable = true;

			// Thread lines overflow slightly
			gtklistitemwidget.overflow = Gtk.Overflow.HIDDEN;
		}
	}

	protected virtual void bind_listitem_cb (GLib.Object item) {
		var obj_widgetable = ((Gtk.ListItem) item).item as WidgetizableForListView;
		if (obj_widgetable == null)
			Process.exit (0);

		try {
			obj_widgetable.fill_widget_with_content (((Gtk.ListItem) item).child);
		} catch (Oopsie e) {
			warning (@"Error bind_listitem_cb: $(e.message)");
			Process.exit (0);
		}
	}

	public override void dispose () {
		base.dispose ();
	}

	public override void clear () {
		base.clear ();
		this.model.remove_all ();
	}

	protected virtual void clear_all_but_first (int i = 1) {
		base.clear ();

		print ("before splice!\n");
		if (model.n_items > i)
			model.splice (i, model.n_items - i, {});
	}

	public override void on_content_changed () {
		if (empty) {
			base_status = new StatusMessage ();
		} else {
			base_status = null;
		}
	}

	public override void unbind_listboxes () {}
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
		((WidgetizableForListView) ((ListModel) content.model).get_item (pos)).open ();
	}
}
