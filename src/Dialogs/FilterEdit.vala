[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/filter_edit.ui")]
public class Tuba.Dialogs.FilterEdit : Adw.Dialog {
	[GtkChild] unowned Adw.EntryRow title_row;
	[GtkChild] unowned Adw.ComboRow expire_in_row;
	[GtkChild] unowned Adw.PreferencesGroup context_group;
	[GtkChild] unowned Adw.PreferencesGroup keywords_group;
	[GtkChild] unowned Gtk.Button save_btn;
	[GtkChild] unowned Adw.SwitchRow hide_row;
	[GtkChild] unowned Adw.ToastOverlay toast_overlay;

	public signal void saved (API.Filters.Filter filter);

	const API.Filters.Filter.ContextType[] ALL_CONTEXT = {HOME, NOTIFICATIONS, PUBLIC, THREAD, ACCOUNT};
	const FilterExpiration[] ALL_EXP = {NEVER, MINUTES_30, HOUR_1, HOUR_6, HOUR_12, DAY_1, WEEK_1};
	enum FilterExpiration {
		NEVER,
		MINUTES_30,
		HOUR_1,
		HOUR_6,
		HOUR_12,
		DAY_1,
		WEEK_1;

		public string to_string () {
			// Use variables to avoid increasing translator work
			// unless they don't exist already

			switch (this) {
				case NEVER: return _("Never");
				case MINUTES_30: return GLib.ngettext ("%d Minute", "%d Minutes", (ulong) 30).printf (30);
				case HOUR_1: return GLib.ngettext ("%d Hour", "%d Hours", (ulong) 1).printf (1);
				case HOUR_6: return GLib.ngettext ("%d Hour", "%d Hours", (ulong) 6).printf (6);
				case HOUR_12: return GLib.ngettext ("%d Hour", "%d Hours", (ulong) 12).printf (12);
				case DAY_1: return GLib.ngettext ("%d Day", "%d Days", (ulong) 1).printf (1);
				case WEEK_1: return GLib.ngettext ("%d Week", "%d Weeks", (ulong) 1).printf (1);
				default: assert_not_reached ();
			}
		}

		public int to_seconds () {
			switch (this) {
				case NEVER: return 0;
				case MINUTES_30: return 1800;
				case HOUR_1: return 3600;
				case HOUR_6: return 21600;
				case HOUR_12: return 43200;
				case DAY_1: return 86400;
				case WEEK_1: return 604800;
				default: assert_not_reached ();
			}
		}

		public static FilterExpiration from_date (string? iso_8601) {
			if (iso_8601 == null) return NEVER;

			var date = new GLib.DateTime.from_iso8601 (iso_8601, null);
			var now = new GLib.DateTime.now_local ();
			if (date.compare (now) < 1) return NEVER;

			var delta = date.difference (now);
			var seconds = delta / TimeSpan.SECOND;

			FilterExpiration res = WEEK_1;
			foreach (var exp in ALL_EXP) {
				if (seconds <= exp.to_seconds ()) {
					res = exp;
					break;
				}
			}

			return res;
		}
	}

	~FilterEdit () {
		context_rows = {};
		keyword_rows = {};
		debug ("Destroying FilterEdit");
	}

	public void validate () {
		// total active context rows
		int context_active = 0;
		// last active context row
		Adw.SwitchRow? last_row = null;
		foreach (var ctx_row in context_rows) {
			ctx_row.row.sensitive = true;
			if (ctx_row.row.active) {
				context_active += 1;
				last_row = ctx_row.row;
			}
		}

		// when there's only one active, we want to make it un-disableable
		if (context_active == 1 && last_row != null) last_row.sensitive = false;

		bool res = title_row.text != "" && context_active > 0;
		save_btn.sensitive = res;
	}

	string? filter_id = null;
	public FilterEdit (Gtk.Widget win, API.Filters.Filter? filter = null) {
		populate_exp_row ();

		if (filter != null) {
			filter_id = filter.id;
			title_row.text = filter.title;
			hide_row.active = filter.tuba_hidden;

			var exp_from_date = FilterExpiration.from_date (filter.expires_at);
			if (exp_from_date != FilterExpiration.NEVER) {
				for (int i = 0; i < ALL_EXP.length; i++) {
					if (exp_from_date == ALL_EXP[i]) {
						expire_in_row.selected = i;
						break;
					}
				}
			}

			populate_context_group (filter.context);
			populate_keywords_group (filter.keywords);
		} else {
			expire_in_row.selected = 0;
			populate_context_group ();
			this.title = _("New Filter");
		}

		validate ();
		this.present (win);
	}

	class ExpWrapper : Object {
		public FilterExpiration exp { get; private set; }
		public string title { get; private set; }

		public ExpWrapper (FilterExpiration exp, string title) {
			this.exp = exp;
			this.title = title;
		}
	}

	private void populate_exp_row () {
		var model = new GLib.ListStore (typeof (ExpWrapper));

		ExpWrapper[] to_add = {};
		foreach (var exp in ALL_EXP) {
			to_add += new ExpWrapper (exp, exp.to_string ());
		}
		model.splice (0, 0, to_add);

		expire_in_row.expression = new Gtk.PropertyExpression (typeof (ExpWrapper), null, "title");
		expire_in_row.model = model;
	}

	struct ContextRow {
		public Adw.SwitchRow row;
		public API.Filters.Filter.ContextType ctx;
	}

	ContextRow[] context_rows = {};
	private void populate_context_group (Gee.ArrayList<string>? contexts = null) {
		foreach (var ctx in ALL_CONTEXT) {
			var row = new Adw.SwitchRow () {
				title = ctx.to_string (),
				active = contexts == null || (contexts != null && contexts.contains (ctx.to_api ()))
			};
			context_rows += ContextRow () {row = row, ctx = ctx};
			row.notify["active"].connect (validate);

			context_group.add (row);
		}
	}

	class KeywordRow : Adw.EntryRow {
		public string? id { get; private set; default=null; }
		public bool should_destroy { get; private set; default=false; }
		public bool whole_word {
			get {
				return word_switch.active;
			}
		}
		public string keyword {
			get {
				return this.text;
			}
		}

		Gtk.Switch word_switch;
		construct {
			this.title = _("Keyword");
			word_switch = new Gtk.Switch () {
				valign = Gtk.Align.CENTER,
				tooltip_text = _("Match Whole Word")
			};
			this.add_suffix (word_switch);
			this.activates_default = false;

			var delete_btn = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
				css_classes = { "circular", "flat", "error" },
				tooltip_text = _("Delete"),
				valign = Gtk.Align.CENTER
			};
			delete_btn.clicked.connect (on_delete);
			this.add_suffix (delete_btn);
		}

		public KeywordRow (API.Filters.FilterKeyword? keyword = null) {
			if (keyword != null) {
				this.id = keyword.id;
				this.text = keyword.keyword;
				word_switch.active = keyword.whole_word;
			}
		}

		private void on_delete () {
			this.should_destroy = true;
			this.visible = false;
		}
	}

	KeywordRow[] keyword_rows = {};
	private void populate_keywords_group (Gee.ArrayList<API.Filters.FilterKeyword> keywords) {
		keywords.@foreach (e => {
			var row = new KeywordRow (e);
			keyword_rows += row;

			keywords_group.add (row);

			return true;
		});
	}

	[GtkCallback]
	private void add_keyword_row () {
		var row = new KeywordRow ();
		keyword_rows += row;
		keywords_group.add (row);
	}

	[GtkCallback]
	void on_title_row_changed () {
		var valid = title_row.text.length > 0;
		Tuba.toggle_css (title_row, !valid, "error");
		validate ();
	}

	[GtkCallback]
	void on_close () {
		force_close ();
	}

	[GtkCallback]
	void on_save_clicked () {
		this.sensitive = false;

		Request req;
		if (filter_id != null) {
			req = new Request.PUT (@"/api/v2/filters/$filter_id");
		} else {
			req = new Request.POST ("/api/v2/filters");
		}

		req
			.with_account (accounts.active)
			.with_form_data ("title", title_row.text)
			.with_form_data ("filter_action", hide_row.active ? "hide" : "warn");

		foreach (var ctx_row in context_rows) {
			if (ctx_row.row.active) {
				req.with_form_data ("context[]", ctx_row.ctx.to_api ());
			}
		}

		var exp = ALL_EXP[expire_in_row.selected];
		req.with_form_data ("expires_in", exp == NEVER ? "" : exp.to_seconds ().to_string ());

		for (int i = 0; i < keyword_rows.length; i++) {
			var row = keyword_rows[i];
			if (row.id != null) {
				req.with_form_data (@"keywords_attributes[$i][id]", row.id);
				req.with_form_data (@"keywords_attributes[$i][_destroy]", row.should_destroy.to_string ());
			} else if (row.should_destroy) continue; // If id is missing but destroy is set to true, just ignore

			req.with_form_data (@"keywords_attributes[$i][whole_word]", row.whole_word.to_string ());
			req.with_form_data (@"keywords_attributes[$i][keyword]", row.keyword);
		}

		req
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				saved (API.Filters.Filter.from (node));
				on_close ();
			})
			.on_error ((code, message) => {
				this.sensitive = true;
				toast_overlay.add_toast (new Adw.Toast (_("Couldn't edit filter: %s").printf (message)) {
					timeout = 0
				});
				warning (@"Couldn't edit filter: $code $message");
			})
			.exec ();
	}
}
