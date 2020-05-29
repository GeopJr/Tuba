public interface Tootle.IStreamListener : GLib.Object {

	public virtual void on_status_removed (int64 id) {}
	public virtual void on_status_added (API.Status s) {}
	public virtual void on_notification (API.Notification n) {}

	public virtual bool accepts (ref string event) {
		return true;
	}

}
