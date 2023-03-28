using Gtk;

// This button prevents changes to its "active" property while it's locked.
//
// This widget is intended to be used with Statuses where their properties
// can be used to drive network requests.

public abstract class Tuba.LockableToggleButton : ToggleButton {

	uint _locks = 0;
	public bool locked {
		get { return this._locks > 0; }
	}

	construct {
		this.toggled.connect (on_toggled);
	}

	protected void set_locked (bool is_locked) {
		if (is_locked)
			_locks++;
		else
			_locks--;
	}

	protected virtual bool can_change () {
		return true;
	}

	protected void on_toggled () {
		if (!locked && can_change()) {
			commit_change ();
		}
	}

	protected abstract void commit_change ();

}
