using GLib;
using Gee;

public class Tooth.InstanceAccount : API.Account, Streamable {

	public const string EVENT_NEW_POST = "update";
	public const string EVENT_DELETE_POST = "delete";
	public const string EVENT_NOTIFICATION = "notification";

	public string? backend { set; get; }
	public string? instance { get; set; }
	public string? client_id { get; set; }
	public string? client_secret { get; set; }
	public string? access_token { get; set; }
	public Error? error { get; set; } //TODO: use this field when server invalidates the auth token

	public GLib.ListStore known_places = new GLib.ListStore (typeof (Place));

	public HashMap<Type,Type> type_overrides = new HashMap<Type,Type> ();

	public new string handle {
		owned get { return @"@$username"; }
	}

	public bool is_active {
		get {
			if (accounts.active == null)
				return false;
			return accounts.active.access_token == access_token;
		}
	}

	public virtual signal void activated () {}
	public virtual signal void deactivated () {}
	public virtual signal void added () {
		subscribed = true;
		check_notifications ();
	}
	public virtual signal void removed () {
		subscribed = false;
	}



	construct {
		this.construct_streamable ();
		this.stream_event[EVENT_NOTIFICATION].connect (on_notification_event);
		this.register_known_places (this.known_places);
	}
	~InstanceAccount () {
		destruct_streamable ();
	}

	public InstanceAccount.empty (string instance){
		Object (
			id: "",
			instance: instance
		);
	}



	// Visibility options

	public class Visibility : Object {
		public string id { get; construct set; }
		public string name { get; construct set; }
		public string icon_name { get; construct set; }
		public string description { get; construct set; }
	}
	public HashMap<string,Visibility> visibility = new HashMap<string,Visibility> ();
	public ListStore visibility_list = new ListStore (typeof (Visibility));
	public void set_visibility (Visibility obj) {
		this.visibility[obj.id] = obj;
		visibility_list.append (obj);
	}



	// Core functions

	public T create_entity<T> (Json.Node node) throws Error {
		var type = typeof (T);
		if (type_overrides.has_key (type))
			type = type_overrides[type];

		return Entity.from_json (type, node);
	}

	public Entity create_dynamic_entity (Type type, Json.Node node) throws Error {
		if (type_overrides.has_key (type))
			type = type_overrides[type];

		return Entity.from_json (type, node);
	}

	public async void verify_credentials () throws Error {
		var req = new Request.GET ("/api/v1/accounts/verify_credentials").with_account (this);
		yield req.await ();

		var node = network.parse_node (req);
		var updated = API.Account.from (node);
		patch (updated);

		message (@"$handle: profile updated");
	}

	public async Entity resolve (string url) throws Error {
		message (@"Resolving URL: \"$url\"...");
		var results = yield API.SearchResults.request (url, this);
		var entity = results.first ();
		message (@"Found $(entity.get_class ().get_name ())");
		return entity;
	}

	public virtual void describe_kind (string kind, out string? icon, out string? descr, API.Account account) {
		icon = null;
		descr = null;
	}

	public virtual void register_known_places (GLib.ListStore places) {}



	// Notifications

	public int unread_count { get; set; default = 0; }
	public int last_read_id { get; set; default = 0; }
	public int last_received_id { get; set; default = 0; }
	public HashMap<int,GLib.Notification> unread_toasts { get; set; default = new HashMap<int,GLib.Notification> (); }
	public ArrayList<Object> notification_inhibitors { get; set; default = new ArrayList<Object> (); }

	public virtual void check_notifications () {
		new Request.GET ("/api/v1/markers?timeline[]=notifications")
			.with_account (this)
			.then ((sess, msg) => {
				var root = network.parse (msg);
				var notifications = root.get_object_member ("notifications");
				last_read_id = int.parse (notifications.get_string_member_with_default ("last_read_id", "0") );
			})
			.exec ();
	}

	public void read_notifications (int up_to_id) {
		message (@"Reading notifications up to id $up_to_id");

		if (up_to_id > last_read_id) {
			last_read_id = up_to_id;

			// TODO: Actually send read req to the instance
		}

		unread_toasts.@foreach (entry => {
			var id = entry.key;
			read_notification (id);
			return true;
		});
	}

	public void read_notification (int id) {
		if (id <= last_read_id) {
			message (@"Read notification with id: $id");
			app.withdraw_notification (id.to_string ());
			unread_toasts.unset (id);
		}
		unread_count = unread_toasts.size;
	}

	public void send_toast (API.Notification obj) {
		var toast = obj.to_toast (this);
		var id = obj.id;
		app.send_notification (id, toast);
		unread_toasts.set (int.parse (id), toast);
	}



	// Streamable

	public string? t_connection_url { get; set; }
	public bool subscribed { get; set; }

	public virtual string? get_stream_url () {
		return @"$instance/api/v1/streaming/?stream=user&access_token=$access_token";
	}

	public virtual void on_notification_event (Streamable.Event ev) {
		var entity = create_entity<API.Notification> (ev.get_node ());

		var id = int.parse (entity.id);
		if (id > last_received_id) {
			last_received_id = id;

			if (notification_inhibitors.is_empty) {
				unread_count++;
				send_toast (entity);
			}
			else {
				read_notifications (last_received_id);
			}
		}
	}

}
