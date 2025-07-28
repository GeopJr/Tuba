public class Tuba.Entity : GLib.Object, Widgetizable, Json.Serializable {

	public virtual bool is_local (InstanceAccount account) {
		return true;
	}

	static bool is_spec_valid (ref ParamSpec spec) {
		return ParamFlags.WRITABLE in spec.flags;
	}

	public override unowned ParamSpec? find_property (string name) {
		if (name.has_prefix ("tuba_")) return null;

		switch (name) {
			case "type":
				return get_class ().find_property ("kind");
			case "value":
				return get_class ().find_property ("val");
			case "params":
				return get_class ().find_property ("props");
			default:
				return get_class ().find_property (name);
		}
	}

	public void patch (GLib.Object with) {
		patch_specs (with, with.get_class ().list_properties ());
	}

	public void patch_specs (GLib.Object obj, ParamSpec[] specs) {
		freeze_notify ();
		foreach (ParamSpec spec in specs) {
			var name = spec.get_name ();
			var defined = find_property (name) != null;
			if (defined && is_spec_valid (ref spec)) {
				var val = Value (spec.value_type);
				obj.get_property (name, ref val);
				base.set_property (name, val);
			}
		}
		thaw_notify ();
	}

	public static Entity from_json (Type type, Json.Node node) throws Error {
		var obj = node.get_object ();
		if (obj == null)
			throw new Oopsie.PARSING (@"Received Json.Node for $(type.name ()) is not a Json.Object!");

		return Json.gobject_deserialize (type, node) as Entity;
	}

	public Json.Node to_json () {
		return Json.gobject_serialize (this);
	}

	public string to_json_data () {
		size_t len;
		return Json.gobject_to_data (this, out len);
	}

	public virtual Type deserialize_array_type (string prop) {
		return typeof (Entity);
	}

	public override bool deserialize_property (string prop, out Value val, ParamSpec spec, Json.Node node) {
		// debug (@"deserializing $prop of type $(val.type_name ())");
		var success = default_deserialize_property (prop, out val, spec, node);

		var type = spec.value_type;
		if (val.type () == Type.INVALID) { // Fix for glib-json < 1.5.1
			val.init (type);
			spec.set_value_default (ref val);
			type = spec.value_type;
		}

		if (type.is_a (typeof (Gee.ArrayList))) {
			Type contains = deserialize_array_type (prop);

			switch (contains) {
				case Type.STRING:
					return des_list_string (out val, node);
				case Type.INT:
					return des_list_int (out val, node);
			}

			return des_list (out val, node, contains);
		}

		return success;
	}

	public static bool des_list (out Value val, Json.Node node, Type type) {
		var arr = new Gee.ArrayList<Entity> ();
		if (!node.is_null ()) {
			node.get_array ().foreach_element ((array, i, elem) => {
				try {
					var obj = Entity.from_json (type, elem);
					arr.add (obj);
				} catch (Error e) {
					warning (@"Error getting Entity from json: $(e.message)");
				}
			});
		}
		val = arr;
		return true;
	}

	public static bool des_list_string (out Value val, Json.Node node) {
		var arr = new Gee.ArrayList<string> ();
		if (!node.is_null ()) {
			node.get_array ().foreach_element ((array, i, elem) => {
				arr.add ((string) elem.get_string ());
			});
		}
		val = arr;
		return true;
	}

	public static bool des_list_int (out Value val, Json.Node node) {
		var arr = new Gee.ArrayList<int> ();
		if (!node.is_null ()) {
			node.get_array ().foreach_element ((array, i, elem) => {
				arr.add ((int) elem.get_int ());
			});
		}
		val = arr;
		return true;
	}

	public override Json.Node serialize_property (string prop, Value val, ParamSpec spec) {
		var type = spec.value_type;
		// debug (@"serializing $prop of type $(val.type_name ())");

		if (type.is_a (typeof (Gee.ArrayList)))
			return ser_list (prop, val, spec);

		return default_serialize_property (prop, val, spec);
	}

	static Json.Node ser_list (string prop, Value val, ParamSpec spec) {
		var list = (Gee.ArrayList<Entity>) val;
		if (list == null)
			return new Json.Node (Json.NodeType.NULL);

		var arr = new Json.Array ();
		list.@foreach (e => {
			var enode = e.to_json ();
			arr.add_element (enode);
			return true;
		});

		var node = new Json.Node (Json.NodeType.ARRAY);
		node.set_array (arr);
		return node;
	}

}
