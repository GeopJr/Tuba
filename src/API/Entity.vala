using Json;

public class Tooth.Entity : GLib.Object, Widgetizable, Json.Serializable {

	public virtual bool is_local (InstanceAccount account) {
		return true;
	}

	static bool is_spec_valid (ref ParamSpec spec) {
		return ParamFlags.WRITABLE in spec.flags;
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

	public void patch (GLib.Object with) {
		patch_specs (with, with.get_class ().list_properties ());
	}

	public void patch_specs (GLib.Object obj, ParamSpec[] specs) {
		freeze_notify ();
		foreach (ParamSpec spec in specs) {
			var name = spec.get_name ();
			var defined = get_class ().find_property (name) != null;
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
				case "supported-mime-types":
				case "languages":
					return des_list_string(out val, node);
				case "media-attachments":
					contains = typeof (API.Attachment);
					break;
				case "mentions":
					contains = typeof (API.Mention);
					break;
				case "emojis":
					contains = typeof (API.Emoji);
					break;
				case "emoji-reactions":
				case "reactions":
					contains = typeof (API.EmojiReaction);
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
				case "history":
					contains = typeof (API.TagHistory);
					break;
				default:
					contains = typeof (Entity);
					break;
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
				var obj = (string) elem.get_string();
				arr.add (obj);
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
