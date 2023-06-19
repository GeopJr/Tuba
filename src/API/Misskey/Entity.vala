using Json;

public class Tuba.Misskey.Entity : Tuba.Entity, Json.Serializable {
    static bool is_spec_valid (ref ParamSpec spec) {
        return Tuba.Entity.is_spec_valid (ref spec);
	}

	public override unowned ParamSpec? find_property (string name) {
		switch (name) {
			case "type":
				return get_class ().find_property ("kind");
			case "value":
				return get_class ().find_property ("val");
			default:
				return get_class ().find_property (name);
		}
	}

    public static Tuba.Misskey.Entity from_json (Type type, Json.Node node) throws Error {
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

	public override bool deserialize_property (string prop, out Value val, ParamSpec spec, Json.Node node) {
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
				case "mentions":
					return des_list_string(out val, node);
				case "emojis":
					contains = typeof (API.Misskey.Emoji);
					break;
				default:
					contains = typeof (Entity);
					break;
			}
			return des_list (out val, node, contains);
		}

		if (type.is_a (typeof (Gee.HashMap))) {
            Type contains;

			switch (prop) {
				case "mentions":
					return des_map_string_string(out val, node);
				default:
					contains = typeof (Entity);
					break;
			}
			return des_map (out val, node, contains);
        }

		return success;
	}

    public static bool des_list (out Value val, Json.Node node, Type type) {
		Tuba.Entity.des_list (out val, node, type);
		return true;
	}

	public static bool des_list_string (out Value val, Json.Node node) {
        Tuba.Entity.des_list_string (out val, node);
		return true;
    }

    public static bool des_map_string_string (out Value val, Json.Node node) {
		var map = new Gee.HashMap<string, string> ();
		if (!node.is_null ()) {
            node.get_object ().foreach_member((obj, t_key, t_node) => {
                map.set (t_key, (string) t_node.get_string ());
            });
		}
		val = map;
		return true;
	}

    public static bool des_map (out Value val, Json.Node node, Type type) {
        var map = new Gee.HashMap<string, Entity> ();
		if (!node.is_null ()) {
            node.get_object ().foreach_member((obj, t_key, t_node) => {
                try {
                    var t_obj = Entity.from_json (type, t_node);
                    map.set (t_key, t_obj);
                } catch (Error e) {
					warning (@"Error getting Entity from json: $(e.message)");
				}
            });
		}
		val = map;
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
