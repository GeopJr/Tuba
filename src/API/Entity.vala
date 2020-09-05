using Json;

public class Tootle.Entity : GLib.Object, Widgetizable, Json.Serializable {

	public static string[] ignore_props = {"formal", "handle", "domain", "has-spoiler"};

	public virtual bool is_local (InstanceAccount account) {
		return true;
	}

	public new ParamSpec[] list_properties () {
		ParamSpec[] specs = {};
		foreach (ParamSpec spec in get_class ().list_properties ()) {
			if (!(spec.name in ignore_props))
				specs += spec;
		}
		return specs;
	}

	public void patch (GLib.Object with) {
		var props = with.get_class ().list_properties ();
		foreach (var prop in props) {
			var name = prop.get_name ();
			var defined = get_class ().find_property (name) != null;
			var forbidden = name in ignore_props;
			if (defined && !forbidden) {
				var val = Value (prop.value_type);
				with.get_property (name, ref val);
				base.set_property (name, val);
			}
		}
	}

	public static Entity from_json (Type type, Json.Node? node) throws Oopsie {
        if (node == null)
            throw new Oopsie.PARSING (@"Received Json.Node for $(type.name ()) is null!");

        var obj = node.get_object ();
        if (obj == null)
            throw new Oopsie.PARSING (@"Received Json.Node for $(type.name ()) is not a Json.Object!");

		//Replace with something more elegant
        var kind = obj.get_member ("type");
        if (kind != null) {
        	obj.set_member ("kind", kind);
        	obj.remove_member ("type");
        }

        var val = obj.get_member ("value");
        if (val != null) {
        	obj.set_member ("val", val);
        	obj.remove_member ("value");
        }

        return Json.gobject_deserialize (type, node) as Entity;
	}

	public Json.Node to_json () {
		return Json.gobject_serialize (this);
	}

	public string to_json_data () {
		size_t len;
		return Json.gobject_to_data (this, out len);
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
			Type contains;

			//There has to be a better way
			switch (prop) {
				case "media-attachments":
					contains = typeof (API.Attachment);
					break;
				case "mentions":
					contains = typeof (API.Mention);
					break;
				case "fields":
					contains = typeof (API.AccountField);
					break;
				case "accounts":
					contains = typeof (API.Account);
					break;
				case "statuses":
					contains = typeof (API.Status);
					break;
				case "hashtags":
					contains = typeof (API.Tag);
					break;
				default:
					contains = typeof (Entity);
					break;
			}
			return des_list (out val, node, contains);
		}
		else if (type.is_a (typeof (API.NotificationType)))
			return des_notification_type (out val, node);

		return success;
	}

	static bool des_notification_type (out Value val, Json.Node node) {
		var str = node.get_string ();
		val = API.NotificationType.from_string (str);
		return true;
	}

	static bool des_list (out Value val, Json.Node node, Type type) {
		if (!node.is_null ()) {
			var arr = new Gee.ArrayList<Entity> ();
			node.get_array ().foreach_element ((array, i, elem) => {
				var obj = Entity.from_json (type, elem);
				arr.add (obj);
			});
			val = arr;
		}
		return true;
	}

	public override Json.Node serialize_property (string prop, Value val, ParamSpec spec) {
		var type = spec.value_type;
		// debug (@"serializing $prop of type $(val.type_name ())");

		if (type.is_a (typeof (Gee.ArrayList)))
			return ser_list (prop, val, spec);
		if (type.is_a (typeof (API.NotificationType)))
			return ser_notification_type (prop, val, spec);

		return default_serialize_property (prop, val, spec);
	}

	static Json.Node ser_notification_type (string prop, Value val, ParamSpec spec) {
		var enum_val = (API.NotificationType) val;
		var node = new Json.Node (NodeType.VALUE);
		node.set_string (enum_val.to_string ());
		return node;
	}

	static Json.Node ser_list (string prop, Value val, ParamSpec spec) {
		var list = (Gee.ArrayList<Entity>) val;
		if (list == null)
			return new Json.Node (NodeType.NULL);

		var arr = new Json.Array ();
		list.@foreach (e => {
			var enode = e.to_json ();
			arr.add_element (enode);
			return true;
		});

		var node = new Json.Node (NodeType.ARRAY);
		node.set_array (arr);
		return node;
	}

}
