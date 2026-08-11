public class Tuba.Cache.Abstract : Object {
	public const string DATA_MIN_REF_COUNT = "refs";

	protected Gee.Map<string, Object> items;

	private uint timeout_source = -1;
	private int _maintenance_secs = 5;
	public int maintenance_secs {
		get {
			return _maintenance_secs;
		}

		set {
			_maintenance_secs = value;
			if (timeout_source != -1)
				GLib.Source.remove (timeout_source);
			setup_maintenance ();
		}
	}

	public uint size {
		get { return items.size; }
	}

	construct {
		items = new Gee.HashMap<string, Object> ();

		setup_maintenance ();
	}

	private void setup_maintenance () {
		timeout_source = Timeout.add_seconds (_maintenance_secs, maintenance_func, Priority.LOW);
	}

	bool maintenance_func () {
		if (size > 0) {
			uint cleared = 0;
			var iter = items.map_iterator ();

			while (iter.has_next ()) {
				iter.next ();
				var obj = iter.get_value ();
				if (obj == null) continue;

				var min_ref_count = obj.get_data<uint> (DATA_MIN_REF_COUNT);
				//  debug (@"[Cache] Key \"$(iter.get_key ())\": $(obj.ref_count)/$(min_ref_count)");
				if (obj.ref_count < min_ref_count) {
					cleared++;
					debug (@"[Cache] Freeing: $(iter.get_key ())");
					iter.unset ();
					obj.dispose ();
				}
			}

			if (cleared > 0)
				debug (@"[Cache] Freed $cleared items from cache. Size: $size");
		}

		return Source.CONTINUE;
	}

	public Object? lookup (string key) {
		return items.@get (key);
	}

	public virtual string get_key (string id) {
		return id;
	}

	public bool contains (string id) {
		return items.has_key (get_key (id));
	}

	public string insert (string id, owned Object obj) {
		var key = get_key (id);
		debug (@"[Cache] Inserting: $key");
		items.@set (key, (owned) obj);

		var nobj = items.@get (key);
		nobj.set_data<uint> (DATA_MIN_REF_COUNT, nobj.ref_count);

		return key;
	}

	public void nuke () {
		debug ("[Cache] Clearing");
		items.clear ();
	}

}
