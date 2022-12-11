using Gtk;

public class Tooth.Views.ContentBase : Views.Base {

	public GLib.ListStore model;
	protected ListBox content;

	public bool empty {
		get { return model.get_n_items () <= 0; }
	}

	construct {
		model = new GLib.ListStore (typeof (Widgetizable));
		model.items_changed.connect (() => on_content_changed ());

		content = new ListBox () {
			selection_mode = SelectionMode.NONE,
			can_focus = false
		};
		content_box.append (content);
		content.add_css_class ("content");
		content.add_css_class ("ttl-content");
		content.row_activated.connect (on_content_item_activated);

		content.bind_model (model, on_create_model_widget);

		scrolled.edge_reached.connect (pos => {
			if (pos == PositionType.BOTTOM)
				on_bottom_reached ();
		});
	}
	~ContentBase () {
		message ("Destroying ContentBase");
	}

	public override void dispose () {
		if (content != null)
			content.bind_model (null, null);
		base.dispose ();
	}

	public override void clear () {
		base.clear ();
		model.remove_all ();
	}

	public override void on_content_changed () {
		if (empty) {
			status_message = STATUS_EMPTY;
			state = "status";
		}
		else {
			state = "content";
		}
	}


	public virtual Widget on_create_model_widget (Object obj) {
		var obj_widgetable = obj as Widgetizable;
		if (obj_widgetable == null)
			Process.exit (0);
		try {
			return obj_widgetable.to_widget ();
		} catch (Oopsie e) {
			warning(@"Error on_create_model_widget: $(e.message)");
			Process.exit (0);
		}
	}

	public virtual void on_bottom_reached () {}

	public virtual void on_content_item_activated (ListBoxRow row) {
		Signal.emit_by_name (row, "open");
	}

}
