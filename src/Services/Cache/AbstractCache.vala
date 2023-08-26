public class Tuba.AbstractCache : Object {

	public const string DATA_MIN_REF_COUNT = "refs";

    protected Gee.Map<string, Object> items;
    protected Gee.Map<string, Soup.Message> items_in_progress;

	private uint timeout_source;
	private int _maintenance_secs = 5;
    public int maintenance_secs {
		get {
			return _maintenance_secs;
		}

		set {
			_maintenance_secs = value;
			GLib.Source.remove (timeout_source);
			setup_maintenance ();
		}
	}

    public uint size {
        get { return items.size; }
    }

    construct {
        items = new Gee.HashMap<string, Object> ();
        items_in_progress = new Gee.HashMap<string, Soup.Message> ();

		setup_maintenance ();
    }

	private void setup_maintenance () {
        timeout_source = Timeout.add_seconds (_maintenance_secs, maintenance_func, Priority.LOW);
	}

	bool maintenance_func () {
		// message ("maintenance start");
		if (size > 0) {
			uint cleared = 0;
			var iter = items.map_iterator ();

			while (iter.has_next ()) {
				iter.next ();
				var obj = iter.get_value ();
				assert (obj != null);

				var min_ref_count = obj.get_data<uint> (DATA_MIN_REF_COUNT);
				// if ("jpg" in iter.get_key ()) {
				// 	warning (@"Key \"$(iter.get_key ())\": $(obj.ref_count)/$(min_ref_count)");
				// }
				if (obj.ref_count < min_ref_count) {
					cleared++;
					message (@"Freeing: $(iter.get_key ())");
					iter.unset ();
					obj.dispose ();
				}
			}

			if (cleared > 0)
				message (@"Freed $cleared items from cache. Size: $size");
		}

		// message ("maintenance end");
		return Source.CONTINUE;
	}

	public Object? lookup (string key) {
		return items.@get (key);
	}

	protected virtual string get_key (string id) {
		return id;
	}

	public bool remove (string id) {
		if (contains (id)) {
			return items.unset (get_key (id));
		}

		return false;
	}

	public bool contains (string id) {
		return items.has_key (get_key (id));
	}

	protected string insert (string id, owned Object obj) {
		var key = get_key (id);
		message (@"Inserting: $key");
		items.@set (key, (owned) obj);

		var nobj = items.@get (key);
		nobj.set_data<uint> (DATA_MIN_REF_COUNT, nobj.ref_count);

		return key;
	}

	public void nuke () {
		message ("Clearing cache");
		items.clear ();
		items_in_progress.clear ();
	}
}
