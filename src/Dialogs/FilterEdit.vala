[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/filter_edit.ui")]
public class Tuba.Dialogs.FilterEdit : Adw.Window {
	[GtkChild] unowned Adw.EntryRow title_row;
	[GtkChild] unowned Adw.ComboRow expire_in_row;
	[GtkChild] unowned Adw.PreferencesGroup context_group;
	[GtkChild] unowned Adw.PreferencesGroup keywords_group;
	[GtkChild] unowned Gtk.Button save_btn;

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
			switch (this) {
				// Use variables to avoid increasing translator work
				// unless they don't exist already

				case NEVER: return _("Never");
				case MINUTES_30: return _("%d Minutes").printf (30);
				case HOUR_1: return _("%d Hour").printf (1);
				case HOUR_6: return _("%d Hours").printf (6);
				case HOUR_12: return _("%d Hours").printf (12);
				case DAY_1: return _("%d Day").printf (1);
				case WEEK_1: return _("1 Week");
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
			if (now.compare (date) < 1) return NEVER;

			var delta = date.difference (now);
			var seconds = delta / TimeSpan.SECOND;

			FilterExpiration res = WEEK_1;
			foreach (var exp in ALL_EXP) {
				if (seconds <= exp.to_seconds ()) {
					res = exp;
					break;
				}
			}

			return WEEK_1;
		}
	}

	~FilterEdit () {
		context_rows = {};
		debug ("Destroying FilterEdit");
	}

	public void is_saveable () {
		bool context_res = false;
		foreach (var row in context_rows) {
			if (row.active) {
				context_res = true;
				break;
			}
		}

		bool res = title_row.text != "" && context_res;
		save_btn.sensitive = res;
	}

	public FilterEdit (Gtk.Window win, API.Filters.Filter? filter = null) {
		this.transient_for = win;
		populate_exp_row ();

		if (filter != null) {
			title_row.text = filter.title;

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
		}

		is_saveable ();
		this.present ();
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

	Adw.SwitchRow[] context_rows = {};
	private void populate_context_group (Gee.ArrayList<string>? contexts = null) {
		foreach (var ctx in ALL_CONTEXT) {
			var row = new Adw.SwitchRow () {
				title = ctx.to_string (),
				active = contexts != null && contexts.contains (ctx.to_api ())
			};
			context_rows += row;
			row.notify["active"].connect (is_saveable);

			context_group.add (row);
		}
	}

	private void populate_keywords_group (Gee.ArrayList<API.Filters.FilterKeyword> keywords) {
		keywords.@foreach (e => {
			var row = new Adw.EntryRow () {
				title = _("Keyword"),
				text = e.keyword
			};
			keywords_group.add (row);

			return true;
		});
	}

	[GtkCallback]
	private void add_keyword_row () {
		var row = new Adw.EntryRow () {
			title = _("Keyword")
		};
		keywords_group.add (row);
	}

	[GtkCallback]
	void on_title_row_changed () {
		var valid = title_row.text.length > 0;
		Tuba.toggle_css (title_row, !valid, "error");
		is_saveable ();
	}

	[GtkCallback]
	void on_close () {
		destroy ();
	}
}
