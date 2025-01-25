public class Tuba.Views.ContentBase : Views.Base {
	protected Gtk.ListBox content;
	protected signal void reached_close_to_top ();
	public GLib.ListStore model;
	private bool bottom_reached_locked = false;

	public bool empty {
		get { return model.get_n_items () <= 0; }
	}

	construct {
		model = new GLib.ListStore (typeof (Widgetizable));

		model.items_changed.connect (on_content_changed);

		content = new Gtk.ListBox () {
			selection_mode = Gtk.SelectionMode.NONE,
			css_classes = { "fake-content", "background" }
		};

		content.row_activated.connect (on_content_item_activated);
		content.bind_model (model, on_create_model_widget);
		content_box.child = content;

		scrolled.vadjustment.value_changed.connect (on_scrolled_vadjustment_value_change);
		scroll_to_top_rev.bind_property ("child-revealed", scroll_to_top_rev, "visible", GLib.BindingFlags.SYNC_CREATE);
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

		var is_close_to_top = scrolled.vadjustment.value <= 100;
		set_scroll_to_top_reveal_child (
			!is_close_to_top
			&& scrolled.vadjustment.value + scrolled.vadjustment.page_size + 100 < scrolled.vadjustment.upper
		);

		if (is_close_to_top) reached_close_to_top ();
	}

	protected void set_scroll_to_top_reveal_child (bool reveal) {
		if (reveal == scroll_to_top_rev.reveal_child) return;
		if (reveal) scroll_to_top_rev.visible = true;

		scroll_to_top_rev.reveal_child = reveal;
	}


	public override void dispose () {
		unbind_listboxes ();
		base.dispose ();
	}

	public override void clear () {
		base.clear ();
		this.model.remove_all ();
	}

	protected virtual void clear_all_but_first (int i = 1) {
		base.clear ();

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

	public override void unbind_listboxes () {
		if (content != null)
			content.bind_model (null, null);
		base.unbind_listboxes ();
	}

	public virtual Gtk.Widget on_create_model_widget (Object obj) {
		var obj_widgetable = obj as Widgetizable;
		if (obj_widgetable == null)
			Process.exit (0);
		try {
			Gtk.Widget widget = obj_widgetable.to_widget ();
			widget.add_css_class ("card");
			widget.add_css_class ("card-spacing");
			widget.focusable = true;

			// Thread lines overflow slightly
			widget.overflow = Gtk.Overflow.HIDDEN;
			return widget;
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

	public virtual void on_content_item_activated (Gtk.ListBoxRow row) {
		Signal.emit_by_name (row, "open");
	}
}
