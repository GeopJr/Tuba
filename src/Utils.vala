public class Tootle.Utils {

	public static void merge (GLib.Object what, GLib.Object with) {
		var props = with.get_class ().list_properties ();
		foreach (var prop in props) {
			var name = prop.get_name ();
			var defined = what.get_class ().find_property (name) != null;
			if (defined) {
				var val = Value (prop.value_type);
				with.get_property (name, ref val);
				what.set_property (name, val) ;
			}
		}
	}

}
