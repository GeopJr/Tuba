public class Tuba.InstanceAccount : API.Account, Streamable {

	public const string EVENT_NEW_POST = "update";
	public const string EVENT_EDIT_POST = "status.update";
	public const string EVENT_DELETE_POST = "delete";
	public const string EVENT_NOTIFICATION = "notification";
	public const string EVENT_CONVERSATION = "conversation";

	public const string KIND_MENTION = "mention";
	public const string KIND_REBLOG = "reblog";
	public const string KIND_FAVOURITE = "favourite";
	public const string KIND_FOLLOW = "follow";
	public const string KIND_POLL = "poll";
	public const string KIND_FOLLOW_REQUEST = "follow_request";
	public const string KIND_REMOTE_REBLOG = "__remote-reblog";
	public const string KIND_EDITED = "update";

	public string? backend { set; get; }
	public API.Instance? instance_info { get; set; }
	public Gee.ArrayList<API.Emoji>? instance_emojis { get; set; }
	public string? instance { get; set; }
	public string? client_id { get; set; }
	public string? client_secret { get; set; }
	public string? access_token { get; set; }
	public Error? error { get; set; } //TODO: use this field when server invalidates the auth token

	public GLib.ListStore known_places = new GLib.ListStore (typeof (Place));

	public Gee.HashMap<Type,Type> type_overrides = new Gee.HashMap<Type,Type> ();

	public new string handle_short {
		owned get { return @"@$username"; }
	}

	public new string handle {
		owned get { return full_handle; }
	}

	public bool is_active {
		get {
			if (accounts.active == null)
				return false;
			return accounts.active.access_token == access_token;
		}
	}

	public virtual signal void activated () {
		gather_instance_info ();
		gather_instance_custom_emojis ();
	}
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

		#if DEV_MODE
			app.dev_new_notification.connect (node => {
				try {
					var entity = create_entity<API.Notification> (node);

					var id = int.parse (entity.id);
					if (id > last_received_id) {
						last_received_id = id;

						unread_count++;
						send_toast (entity);
					}
				} catch (Error e) {
					warning (@"on_notification_event: $(e.message)");
				}
			});
		#endif
	}
	~InstanceAccount () {
		destruct_streamable ();
	}

	public InstanceAccount.empty (string instance) {
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

		private string? _small_icon_name = null;
		public string small_icon_name {
			get {
				return _small_icon_name ?? icon_name;
			}
			set {
				_small_icon_name = value;
			}
		}
	}
	public Gee.HashMap<string,Visibility> visibility = new Gee.HashMap<string,Visibility> ();
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

		update_object (req.response_body);
	}

	public void update_object (InputStream in_stream) throws Error {
		var parser = Network.get_parser_from_inputstream (in_stream);
		var node = network.parse_node (parser);
		var updated = API.Account.from (node);
		patch (updated);

		debug (@"$handle: profile updated");
	}

	public async Entity resolve (string url) throws Error {
		debug (@"Resolving URL: \"$url\"…");
		var results = yield API.SearchResults.request (url, this);
		var entity = results.first ();
		debug (@"Found $(entity.get_class ().get_name ())");
		return entity;
	}

	public struct Kind {
		string? icon;
		string? description;
		string? url;
	}

	public virtual void describe_kind (
		string kind,
		out Kind result,
		string? actor_name = null,
		string? callback_url = null
	) {
		switch (kind) {
			case KIND_MENTION:
				result = {
					"tuba-chat-symbolic",
					_("%s mentioned you").printf (actor_name),
					callback_url
				};
				break;
			case KIND_REBLOG:
				result = {
					"tuba-media-playlist-repeat-symbolic",
					_("%s boosted your post").printf (actor_name),
					callback_url
				};
				break;
			case KIND_REMOTE_REBLOG:
				result = {
					"tuba-media-playlist-repeat-symbolic",
					_("%s boosted").printf (actor_name),
					callback_url
				};
				break;
			case KIND_FAVOURITE:
				result = {
					"tuba-starred-symbolic",
					_("%s favorited your post").printf (actor_name),
					callback_url
				};
				break;
			case KIND_FOLLOW:
				result = {
					"tuba-contact-new-symbolic",
					_("%s now follows you").printf (actor_name),
					callback_url
				};
				break;
			case KIND_FOLLOW_REQUEST:
				result = {
					"tuba-contact-new-symbolic",
					_("%s wants to follow you").printf (actor_name),
					callback_url
				};
				break;
			case KIND_POLL:
				result = {
					"tuba-check-round-outline-symbolic",
					_("Poll results"),
					null
				};
				break;
			case KIND_EDITED:
				result = {
					"document-edit-symbolic",
					_("%s edited a post").printf (actor_name),
					null
				};
				break;
			default:
				result = {
					null,
					null,
					null
				};
				break;
		}
	}

	public virtual void register_known_places (GLib.ListStore places) {}

	// Notifications

	public int unread_count { get; set; default = 0; }
	public int last_read_id { get; set; default = 0; }
	public int last_received_id { get; set; default = 0; }
	private bool passed_init_notifications = false;

	public class StatusContentType : Object {
		public string mime { get; construct set; }
		public string icon_name { get; construct set; }
		public string title { get; construct set; }

		public StatusContentType (string content_type) {
			mime = content_type;

			switch (content_type.down ()) {
				case "text/plain":
					icon_name = "tuba-paper-symbolic";
					// translators: this is a content type
					title = _("Plain Text");
					break;
				case "text/html":
					icon_name = "tuba-code-symbolic";
					title = "HTML";
					break;
				case "text/markdown":
					icon_name = "tuba-markdown-symbolic";
					title = "Markdown";
					break;
				case "text/bbcode":
					icon_name = "tuba-rich-text-symbolic";
					title = "BBCode";
					break;
				case "text/x.misskeymarkdown":
					icon_name = "tuba-rich-text-symbolic";
					title = "MFM";
					break;
				default:
					icon_name = "tuba-rich-text-symbolic";

					int slash = content_type.index_of_char ('/');
					int ct_l = content_type.length;
					if (slash == -1 || slash == ct_l) {
						title = content_type.up ();
					} else {
						title = content_type.slice (slash + 1, ct_l).up ();
					}

					break;
			}
		}

		public static EqualFunc<string> compare = (a, b) => {
			return ((StatusContentType) a).mime == ((StatusContentType) b).mime;
		};
	}

	public GLib.ListStore supported_mime_types = new GLib.ListStore (typeof (StatusContentType));
	public void gather_instance_info () {
		new Request.GET ("/api/v1/instance")
			.with_account (this)
			.then ((sess, msg, in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				instance_info = API.Instance.from (node);

				var content_types = instance_info.compat_supported_mime_types;
				if (content_types != null) {
					supported_mime_types.remove_all ();
					foreach (string content_type in content_types) {
						supported_mime_types.append (new StatusContentType (content_type));
					}
				}
			})
			.exec ();
	}

	public void gather_instance_custom_emojis () {
		new Request.GET ("/api/v1/custom_emojis")
			.with_account (this)
			.then ((sess, msg, in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				Value res_emojis;
				Entity.des_list (out res_emojis, node, typeof (API.Emoji));
				instance_emojis = (Gee.ArrayList<Tuba.API.Emoji>) res_emojis;
			})
			.exec ();
	}

	public void init_notifications () {
		if (passed_init_notifications) return;

		new Request.GET ("/api/v1/notifications")
			.with_account (this)
			.with_param ("min_id", last_read_id.to_string ())
			.then ((sess, msg, in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var array = Network.get_array_mstd (parser);
				if (array != null) {
					unread_count = (int)array.get_length ();
					if (unread_count > 0) {
						last_received_id = int.parse (array.get_object_element (0).get_string_member_with_default ("id", "-1"));
					}
				}
				passed_init_notifications = true;
			})
			.exec ();
	}

	public virtual void check_notifications () {
		new Request.GET ("/api/v1/markers?timeline[]=notifications")
			.with_account (this)
			.then ((sess, msg, in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var root = network.parse (parser);
				if (!root.has_member ("notifications")) return;
				var notifications = root.get_object_member ("notifications");
				last_read_id = int.parse (notifications.get_string_member_with_default ("last_read_id", "-1") );
				if (!passed_init_notifications) init_notifications ();
			})
			.exec ();
	}

	public void read_notifications (int up_to_id) {
		debug (@"Reading notifications up to id $up_to_id");

		if (up_to_id > last_read_id) {
			last_read_id = up_to_id;

			if (last_read_id != -1) {
				// Mark as read
				new Request.POST ("/api/v1/markers")
					.with_account (this)
					.with_form_data ("notifications[last_read_id]", up_to_id.to_string ())
					.then (() => {})
					.exec ();

				// Pleroma FE doesn't mark them as read by just updating the marker
				if (instance_info != null && instance_info?.pleroma != null) {
					new Request.POST ("/api/v1/pleroma/notifications/read")
						.with_account (this)
						.with_form_data ("max_id", up_to_id.to_string ())
						.then (() => {})
						.exec ();
				}

				sent_notifications.clear ();
			}
		}

		unread_count = 0;

		//  if (sent_notification_ids.size > 0) {
		//  	sent_notification_ids.@foreach (entry => {
		//  		app.withdraw_notification (entry);
		//  		return true;
		//  	});
		//  }
		//  unread_toasts.@foreach (entry => {
		//  	var id = entry.key;
		//  	read_notification (id);
		//  	return true;
		//  });
	}

	//  public void read_notification (int id) {
	//  	if (id <= last_read_id) {
	//  		debug (@"Read notification with id: $id");
	//  		app.withdraw_notification (id.to_string ());
	//  		unread_toasts.unset (id);
	//  	}
	//  	unread_count = unread_toasts.size;
	//  	has_unread = unread_count > 0;
	//  }

	private Gee.HashMap<string, int> sent_notifications = new Gee.HashMap<string, int> ();
	private const string[] GROUPED_KINDS = {
		KIND_FAVOURITE,
		KIND_REBLOG
	};
	public void send_toast (API.Notification obj) {
		if (obj.kind != null && (obj.kind in settings.muted_notification_types)) return;

		var id = obj.id;
		var others = 0;

		if (settings.group_push_notifications && obj.status != null && obj.kind in GROUPED_KINDS) {
			id = @"$(obj.status.id)-$(obj.kind)";
			if (sent_notifications.has_key (id)) {
				others = sent_notifications.get (id) + 1;
			}
			sent_notifications.set (id, others);
		}

		var toast = obj.to_toast (this, others);
		app.send_notification (id, toast);
		//  sent_notification_ids.add(id);
	}



	// Streamable

	public string? t_connection_url { get; set; }
	public bool subscribed { get; set; }

	public virtual string? get_stream_url () {
		if (instance == null || access_token == null) return null;
		return @"$instance/api/v1/streaming/?stream=user:notification&access_token=$access_token";
	}

	public virtual void on_notification_event (Streamable.Event ev) {
		try {
			var entity = create_entity<API.Notification> (ev.get_node ());

			var id = int.parse (entity.id);
			if (id > last_received_id) {
				last_received_id = id;

				unread_count++;
				send_toast (entity);
			}
		} catch (Error e) {
			warning (@"on_notification_event: $(e.message)");
		}
	}

	// Notification actions
	public virtual void open_status_url (string url) {}
	public virtual void answer_follow_request (string issuer_id, string fr_id, bool accept) {}
	public virtual void follow_back (string issuer_id, string acc_id) {}
	public virtual void reply_to_status_uri (string issuer_id, string uri) {}
	public virtual void remove_from_followers (string issuer_id, string acc_id) {}
}
