public class Tuba.API.Relationship : Entity {

	public signal void invalidated ();
	public bool tuba_has_loaded { get; set; default=false; }

	public string id { get; set; default = ""; }
	public bool following { get; set; default = false; }
	public bool followed_by { get; set; default = false; }
	public bool showing_reblogs { get; set; default = true; }
	public bool muting { get; set; default = false; }
	public bool muting_notifications { get; set; default = false; }
	public bool requested { get; set; default = false; }
	public bool blocking { get; set; default = false; }
	public bool blocked_by { get; set; default = false; }
	public bool domain_blocking { get; set; default = false; }
	public bool notifying { get; set; default = false; }
	public string? note { get; set; default = null; }

	public string to_string () {
		string label = "";

		if (requested)
			label = _("Sent follow request");
		else if (followed_by && following)
			label = _("Mutuals");
		else if (followed_by)
			label = _("Follows you");
		else if (blocked_by)
			// translators: as in, you've been blocked by them
			label = _("Blocks you");

		return label;
	}

	public Relationship.for_account (API.Account acc) {
		Object (id: acc.id);
		request ();
	}

	public Relationship.for_account_id (string t_id) {
		Object (id: t_id);
		request ();
	}

	public void request () {
		new Request.GET ("/api/v1/accounts/relationships")
			.with_account (accounts.active)
			.with_param ("id", id)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				Network.parse_array (parser, node => {
					invalidate (node);
				});
			})
			.exec ();
	}

	public static async Gee.HashMap<string, API.Relationship> request_many (string[] ids) throws Error {
		Gee.HashMap<string, API.Relationship> res = new Gee.HashMap<string, API.Relationship> ();

		var id_array = Request.array2string (new Gee.ArrayList<string>.wrap (ids), "id");
		var req = new Request.GET (@"/api/v1/accounts/relationships?$id_array")
			.with_account (accounts.active);
		yield req.await ();

		var parser = Network.get_parser_from_inputstream (req.response_body);
		Network.parse_array (parser, node => {
			API.Relationship entity = Entity.from_json (typeof (API.Relationship), node) as API.Relationship;
			entity.tuba_has_loaded = true;
			res.set (entity.id, entity);
		});

		return res;
	}

	void invalidate (Json.Node node) throws Error {
		var rs = Entity.from_json (typeof (API.Relationship), node) as API.Relationship;
		patch (rs);
		tuba_has_loaded = true;
		invalidated ();
	}

	public struct ModifyParam {
		public string param;
		public string val;
	}

	public void modify (string operation, ModifyParam[]? modify_params = null) {
		var req = new Request.POST (@"/api/v1/accounts/$id/$operation")
			.with_account (accounts.active)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				invalidate (node);
				debug (@"Performed \"$operation\" on Relationship $id");
			});

		if (modify_params != null) {
			foreach (ModifyParam modify_param in modify_params) {
				req.with_param (modify_param.param, modify_param.val);
			}
		}


		req.exec ();
	}

	public void modify_note (string comment) {
		var builder = new Json.Builder ();
		builder.begin_object ();

		builder.set_member_name ("comment");
		builder.add_string_value (comment);

		builder.end_object ();

		new Request.POST (@"/api/v1/accounts/$id/note")
			.with_account (accounts.active)
			.body_json (builder)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				invalidate (node);
				debug (@"Performed \"note\" on Relationship $id");
			})
			.exec ();
	}

	public void question_modify_block (string handle, bool block = true) {
		// translators: the variable is a user handle
		var q = block ? _("Block \"%s\"?") : _("Unblock \"%s\"?");

		app.question.begin (
			{q.printf (handle), false},
			null,
			app.main_window,
			{ { block ? _("Block") : _("Unblock"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
			null,
			false,
			(obj, res) => {
				if (app.question.end (res).truthy ()) modify (block ? "block" : "unblock");
			}
		);
	}

	public void question_modify_mute (string handle) {
		var switch_row = new Adw.SwitchRow () {
			title = _("Hide from Notifications"),
			active = true
		};

		var model = new GLib.ListStore (typeof (MuteExpWrapper));
		MuteExpWrapper[] to_add = {};
		foreach (MuteExpiration exp in ALL_MUTE_EXPS) {
			to_add += new MuteExpWrapper (exp, exp.to_string ());
		}
		model.splice (0, 0, to_add);

		var exp_row = new Adw.ComboRow () {
			expression = new Gtk.PropertyExpression (typeof (MuteExpWrapper), null, "title"),
			model = model,
			title = _("Expire In")
		};

		var list_box = new Gtk.ListBox () {
			selection_mode = Gtk.SelectionMode.NONE,
			css_classes = {"boxed-list"}
		};

		list_box.append (exp_row);
		list_box.append (switch_row);

		app.question.begin (
			// translators: the variable is a user handle
			{_("Mute \"%s\"?").printf (handle), false},
			null,
			app.main_window,
			{ { _("Mute"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
			list_box,
			false,
			(obj, res) => {
				if (app.question.end (res).truthy ()) {
					modify ("mute", {
						{ "notifications", switch_row.active.to_string () },
						{ "duration", ((MuteExpWrapper) exp_row.selected_item).exp.to_seconds ().to_string () }
					});
				}
			}
		);
	}

	class MuteExpWrapper : Object {
		public MuteExpiration exp { get; private set; }
		public string title { get; private set; }

		public MuteExpWrapper (MuteExpiration exp, string title) {
			this.exp = exp;
			this.title = title;
		}
	}

	const MuteExpiration[] ALL_MUTE_EXPS = { NEVER, HOUR_24, DAY_7, DAY_30 };
	enum MuteExpiration {
		NEVER,
		HOUR_24,
		DAY_7,
		DAY_30;

		public string to_string () {
			// Use variables to avoid increasing translator work
			// unless they don't exist already

			switch (this) {
				case NEVER: return _("Never");
				case HOUR_24: return GLib.ngettext ("%d Hour", "%d Hours", (ulong) 24).printf (24);
				case DAY_7: return GLib.ngettext ("%d Day", "%d Days", (ulong) 7).printf (7);
				case DAY_30: return GLib.ngettext ("%d Day", "%d Days", (ulong) 30).printf (30);
				default: assert_not_reached ();
			}
		}

		public int to_seconds () {
			switch (this) {
				case NEVER: return 0;
				case HOUR_24: return 3600 * 24;
				case DAY_7: return 3600 * 24 * 7;
				case DAY_30: return 3600 * 24 * 30;
				default: assert_not_reached ();
			}
		}
	}
}
