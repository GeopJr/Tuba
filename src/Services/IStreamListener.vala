public interface Tootle.IStreamListener : GLib.Object {

	public signal void on_status_removed (int64 id);
	public signal void on_status_added (API.Status s);
	public signal void on_notification (API.Notification n);

}
