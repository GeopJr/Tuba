public class Tuba.Dialogs.Components.Polls : Gtk.Box {
	public class PollRow : Adw.EntryRow {
		public bool is_empty { get; private set; default=true; }
		public bool is_valid { get; private set; default=false; }
		public Gtk.Button delete_button { get; private set; }
		public signal void deleted (PollRow row);

		construct {
			delete_button = new Gtk.Button () {
				icon_name = "user-trash-symbolic",
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER,
				css_classes = { "flat", "circular", "error" }
			};
			delete_button.clicked.connect (on_delete_button_clicked);

			add_suffix (delete_button);
			changed.connect (check_valid);
			check_valid ();
		}

		~PollRow () {
			is_valid = false;
		}

		private void on_delete_button_clicked () {
			deleted (this);
		}

		private void check_valid () {
			var text_count = text.char_count ();
			var passed_limit = text_count > accounts.active.instance_info.compat_status_poll_max_characters;

			is_empty = text_count == 0;
			is_valid = !passed_limit;
			if (!is_valid) {
				add_css_class ("error");
			} else {
				remove_css_class ("error");
			}
		}
	}

	public class Expiration : GLib.Object {
		public string text { get; set; }
		public int64 value { get; set; }

		public Expiration (string? text, int64 value) {
			Object (text: text, value: value);
		}

		public static EqualFunc<string> compare = (a, b) => {
			return ((Expiration) a).value >= ((Expiration) b).value;
		};
	}

	protected class StatefulButton : Gtk.Button {
		public struct State {
			public string active;
			public string inactive;
		}

		private bool _active = false;
		public bool active {
			get { return _active; }
			set {
				_active = value;
				content.icon_name = _active ? this.icon.active : this.icon.inactive;
				content.label = _active ? this.title.active : this.title.inactive;
			}
		}

		public State icon { get; set; }
		public State title { get; set; }
		Adw.ButtonContent content;
		construct {
			content = new Adw.ButtonContent () {
				can_shrink = true
			};
			this.child = content;

			this.clicked.connect (on_clicked);
		}

		public StatefulButton (State icon, State title, bool active = false) {
			this.icon = icon;
			this.title = title;
			this.active = active;
		}

		private void on_clicked () {
			this.active = !this.active;
		}
	}

	Gee.ArrayList<PollRow> poll_options = new Gee.ArrayList<PollRow> ();
	Gtk.ListBox poll_list;
	Gtk.DropDown expiration_button;
	StatefulButton multi_button;
	StatefulButton show_results_button;

	public bool hide_totals { get { return !show_results_button.active; } }
	public bool multiple_choice { get { return multi_button.active; } }
	public bool can_delete { get; private set; default=false; }
	public bool is_valid { get; set; default=false; }

	construct {
		this.orientation = VERTICAL;
		this.spacing = 12;

		poll_list = new Gtk.ListBox () {
			css_classes = { "boxed-list" },
			selection_mode = Gtk.SelectionMode.NONE
		};
		this.append (poll_list);

		install_expires_in ();
		multi_button = new StatefulButton (
			{ "tuba-checkbox-checked-symbolic", "tuba-radio-checked-symbolic" },
			{ _("Multiple Choice"), _("Single Choice") }
		) {
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			css_classes = {"composer-toggle-button"}
		};

		show_results_button = new StatefulButton (
			{ "tuba-eye-open-negative-filled-symbolic", "tuba-eye-not-looking-symbolic" },
			// translators: multiple choice as in allow the user to pick multiple poll options
			{ _("Show Results"), _("Hide Results") },
			true
		) {
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			css_classes = {"composer-toggle-button"}
		};

		var actions_box = new Gtk.Box (HORIZONTAL, 6) {
			homogeneous = true,
			halign = CENTER
		};
		actions_box.append (multi_button);
		actions_box.append (show_results_button);
		actions_box.append (expiration_button);
		this.append (actions_box);

		add_poll_row ();
		add_poll_row ();

		this.add_css_class ("initial-font-size");
	}

	private void check_poll_items () {
		var poll_options_amount = poll_options.size;
		this.can_delete = poll_options_amount > 2;

		//  poll_list.remove (add_poll_button);
		//  if (poll_options_amount < accounts.active.instance_info.compat_status_poll_max_options) {
		//  	poll_list.append (add_poll_button);
		//  }
	}

	private PollRow add_poll_row (string? content = null) {
		var row = new PollRow () {
			// translators: poll entry title; the variable is a number
			title = _("Choice %d").printf (poll_options.size + 1)
		};

		if (content != null) row.text = content;

		poll_options.add (row);
		poll_list.append (row);

		bind_property ("can-delete", row.delete_button, "visible", GLib.BindingFlags.SYNC_CREATE);
		row.deleted.connect (remove_poll_row);
		row.notify["is-valid"].connect (on_row_invalid);
		row.changed.connect_after (row_cleanup);
		on_row_invalid ();

		check_poll_items ();

		return row;
	}

	private void row_cleanup () {
		if (poll_options.size < 2) return;

		var last_poll_row = poll_options.last ();
		bool is_empty = last_poll_row.is_empty;
		if (!is_empty && poll_options.size < accounts.active.instance_info.compat_status_poll_max_options) {
			add_poll_row ();
		} else if (is_empty && this.can_delete) {
			var second_last_poll_row = poll_options.get (poll_options.size - 2);
			if (second_last_poll_row.is_empty) {
				poll_options.remove (last_poll_row);
				poll_list.remove (last_poll_row);
			}
		}
	}

	private void remove_poll_row (PollRow row) {
		poll_options.remove (row);
		poll_list.remove (row);

		var i = 0;
		foreach (var t_row in poll_options) {
			i++;
			t_row.title = _("Choice %d").printf (i);
		}

		is_valid = !check_invalid ();
		check_poll_items ();
		row_cleanup ();
	}

	public bool check_invalid () {
		var any_invalid = false;
		foreach (var t_row in poll_options) {
			any_invalid = !t_row.is_valid;
			if (any_invalid) break;
		}
		return any_invalid;
	}

	private void on_row_invalid () {
		this.is_valid = !check_invalid ();
		row_cleanup ();
	}

	Expiration[] expirations = {
		// translators: the variable is a number
		new Expiration (GLib.ngettext ("%d Minute", "%d Minutes", (ulong) 5).printf (5), 300),
		new Expiration (GLib.ngettext ("%d Minute", "%d Minutes", (ulong) 30).printf (30), 1800),
		// translators: the variable is a number
		new Expiration (GLib.ngettext ("%d Hour", "%d Hours", (ulong) 1).printf (1), 3600),
		new Expiration (GLib.ngettext ("%d Hour", "%d Hours", (ulong) 6).printf (6), 21600),
		new Expiration (GLib.ngettext ("%d Hour", "%d Hours", (ulong) 12).printf (12), 43200),
		// translators: the variable is a number
		new Expiration (GLib.ngettext ("%d Day", "%d Days", (ulong) 1).printf (1), 86400),
		new Expiration (GLib.ngettext ("%d Day", "%d Days", (ulong) 3).printf (3), 259200),
		new Expiration (GLib.ngettext ("%d Day", "%d Days", (ulong) 7).printf (7), 604800)
	};

	protected void install_expires_in (string? expires_at = null) {
		var store = new GLib.ListStore (typeof (Expiration));

		int64 min = accounts.active.instance_info.compat_status_poll_min_expiration;
		int64 max = accounts.active.instance_info.compat_status_poll_max_expiration;

		if (min > 604800) min = 0;
		if (max < 300) max = 604800;

		int one_day_index = -1;
		int exp_count = -1;
		foreach (var expiration in expirations) {
			if (min <= expiration.value && max >= expiration.value) {
				store.append (expiration);
				exp_count = exp_count + 1;
				if (expiration.value <= 86400) one_day_index = exp_count;
			}
		}

		expiration_button = new Gtk.DropDown (store, null) {
			expression = new Gtk.PropertyExpression (typeof (Expiration), null, "text"),
			factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/expiration.ui"),
			list_factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/expiration.ui"),
			tooltip_text = _("Expiration"),
			enable_search = false
		};
		expiration_button.add_css_class ("dropdown-border-radius");

		if (expires_at != null) {
			var date = new GLib.DateTime.from_iso8601 (expires_at, null);
			var now = new GLib.DateTime.now_local ();
			var delta = date.difference (now);

			uint default_exp_index;
			if (
				store.find_with_equal_func (
					new Expiration (null, delta / TimeSpan.SECOND),
					Expiration.compare,
					out default_exp_index
				)
			) {
				expiration_button.selected = default_exp_index;
			}
		} else if (one_day_index > -1) {
			expiration_button.selected = one_day_index;
		}
	}
}
