using Gtk;

public class Tooth.StatusActionButton : LockableToggleButton {

	public Request req { get; set; default = null; }

	public Object object { get; set; default = null; }
	public string prop_name { get; set; }
	public string action_on { get; construct set; }
	public string action_off { get; construct set; }

	~StatusActionButton() {
		if (object != null) {
			object.notify[prop_name].disconnect (on_object_notify);
		}
	}

	public void bind (Object obj) {
		this.object = obj;
		active = get_value ();
		set_class_enabled(active);
		object.notify[prop_name].connect (on_object_notify);
	}

	protected void set_class_enabled(bool is_active = true) {
		if (is_active) { 
			add_css_class("enabled");
		} else {
			remove_css_class("enabled");
		}
	}

	protected void on_object_notify (ParamSpec pspec) {
		if (locked)
			return;

		set_locked(true);
		var val = get_value ();
		active = val;
		set_class_enabled(active);
		set_locked(false);
	}

	protected void set_value (bool state) {
		var val = Value (Type.BOOLEAN);
		val.set_boolean (state);
		object.set_property (prop_name, val);
		active = val.get_boolean ();
		set_class_enabled(active);
	}

	protected bool get_value () {
		var val = Value (Type.BOOLEAN);
		object.get_property (prop_name, ref val);
		return val.get_boolean();
	}

	protected override bool can_change () {
		if (object == null) {
			warning ("No object to operate on. Did you forget to bind the status?");
			return false;
		}

		if (req != null)
			return false; // Don't send another request if there's one already pending

		return active != get_value (); // Ignore if this got triggered while unchanged.
	}

	protected override void commit_change () {
		var entity = object as API.Status;
		var action = !active ? action_off : action_on;
		req = entity.action (action);

		set_locked(true);

		message (@"Performing status action '$action'...");
		req.await.begin ((o, res) => {
			try {
				var msg = req.await.end (res);
				var node = network.parse_node (msg);

				var jobj = node.get_object ();
				var received_value = jobj.get_boolean_member (prop_name);
				set_value (received_value);
				message (@"Status action '$action' complete");
			}
			catch (Error e) {
				warning (@"Couldn't perform action \"$action\" on a Status:");
				warning (e.message);
				app.inform (Gtk.MessageType.WARNING, _("Network Error"), e.message);
			}

			req = null;
			set_locked(false);
		});
	}

}
