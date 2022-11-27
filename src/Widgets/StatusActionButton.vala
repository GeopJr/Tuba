using Gtk;

public class Tooth.StatusActionButton : LockableToggleButton {

	public Request req { get; set; default = null; }

	public Object object { get; set; default = null; }
	public string prop_name { get; set; }
	public string action_on { get; construct set; }
	public string action_off { get; construct set; }
	public string icon_toggled_name { get; set; default = null; }
	public string default_icon_name { get; set; default = null; }
	public bool increase_fav { get; set; default = false; }
	public bool increase_reblog { get; set; default = false; }

	~StatusActionButton() {
		if (object != null) {
			object.notify[prop_name].disconnect (on_object_notify);
		}
	}

	public void bind (Object obj) {
		this.object = obj;
		active = get_value ();
		set_class_enabled(active);
		set_toggled_icon(active);
		object.notify[prop_name].connect (on_object_notify);
	}

	protected void set_class_enabled(bool is_active = true) {
		if (is_active) { 
			add_css_class("enabled");
		} else {
			remove_css_class("enabled");
		}
	}

	protected void set_toggled_icon(bool is_active = true) {
		if (icon_toggled_name != null) {
			if (this.icon_name != null && this.default_icon_name == null) {
				default_icon_name = this.icon_name;
			}
			if (is_active) {
				this.icon_name = icon_toggled_name;
			} else {
				this.icon_name = default_icon_name;
			}
		}
	}

	protected void on_object_notify (ParamSpec pspec) {
		if (locked)
			return;

		set_locked(true);
		var val = get_value ();
		active = val;
		set_locked(false);
	}

	protected void set_value (bool state) {
		var val = Value (Type.BOOLEAN);
		val.set_boolean (state);
		object.set_property (prop_name, val);
		active = val.get_boolean ();
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

	protected void update_stats (API.Status obj, string action) {
		if (action == "favourite") {
			obj.favourites_count++;
		} else if (action == "unfavourite") {
			obj.favourites_count--;
		} else if (action == "reblog") {
			obj.reblogs_count++;
		} else if (action == "unreblog") {
			obj.reblogs_count--;
		}
	}

	protected override void commit_change () {
		var entity = object as API.Status;
		var action = !active ? action_off : action_on;
		req = entity.action (action);

		set_locked(true);
		set_class_enabled(active);
		set_toggled_icon(active);

		message (@"Performing status action '$action'...");
		req.await.begin ((o, res) => {
			try {
				var msg = req.await.end (res);
				var node = network.parse_node (msg);

				var jobj = node.get_object ();
				var received_value = jobj.get_boolean_member (prop_name);
				set_value (received_value);
				update_stats(entity, action);
				message (@"Status action '$action' complete");
			}
			catch (Error e) {
				warning (@"Couldn't perform action \"$action\" on a Status:");
				warning (e.message);
				update_stats(entity, active ? action_off : action_on);
				app.inform (Gtk.MessageType.WARNING, _("Network Error"), e.message);
				set_class_enabled(!active);
				set_toggled_icon(!active);
			}

			req = null;
			set_locked(false);
		});
	}

}
