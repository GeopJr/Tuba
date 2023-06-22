public class Tuba.PollPage : ComposerPage {
	public class Poll : Adw.EntryRow {
		public bool is_valid { get; private set; default=false; }
		public Gtk.Button delete_button { get; private set; }
		public signal void deleted (Poll row);

		construct {
			delete_button = new Gtk.Button () {
				icon_name = "tuba-trash-symbolic",
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER,
				css_classes = { "flat", "circular", "error" }
			};
			delete_button.clicked.connect (on_delete_button_clicked);

			add_suffix (delete_button);
			changed.connect (check_valid);
			check_valid ();
		}

		~Poll () {
			is_valid = false;
		}

		private void on_delete_button_clicked () {
			deleted (this);
		}

		private void check_valid () {
			var text_count = text.char_count ();
			var passed_limit = text_count > accounts.active.instance_info.compat_status_poll_max_characters;
	
			if (passed_limit || text_count == 0) {
				add_css_class ("error");
			} else {
				remove_css_class ("error");
			}

			is_valid = !passed_limit && text_count > 0;
		}
	}

	public class Expiration : GLib.Object {
		public string text { get; set; }
		public string text_short { get; set; }
		public int64 value { get; set; }

		public Expiration (string? text, string? text_short, int64 value) {
			Object (text: text, text_short: text_short, value: value);
		}

		public static EqualFunc<string> compare = (a, b) => {
			return ((Expiration) a).value >= ((Expiration) b).value;
		};
	}

	Gee.ArrayList<Tuba.PollPage.Poll> poll_options = new Gee.ArrayList<Tuba.PollPage.Poll>();
	Gtk.ListBox poll_list;
	Gtk.Button add_poll_action_button;
	public bool hide_totals { get; set; default=false; }
	public bool multiple_choice { get; set; default=false; }
	public bool can_delete { get; private set; default=false; }
	public bool is_valid { get; set; default=false; }

	private bool _can_publish = false;
	public override bool can_publish {
		get {
			return _can_publish;
		}

		set {
			_can_publish = value && is_valid;
		}
	}

	construct {
		title = _("Poll");
		icon_name = "tuba-text-justify-left-symbolic";
	}

	private void check_poll_items () {
		var poll_options_amount = poll_options.size;

		can_delete = poll_options_amount > 2;
		add_poll_action_button.sensitive = poll_options_amount < accounts.active.instance_info.compat_status_poll_max_options;
	}

	// Using lambdas causes memory leaks
	private void add_poll_row_without_title () {
		add_poll_row ();
	}

	public override void on_build () {
		base.on_build ();

		poll_list = new Gtk.ListBox () {
			css_classes = { "boxed-list" }
		};

		var clamp = new Adw.Clamp () {
			child = poll_list,
			tightening_threshold = 100,
			valign = Gtk.Align.CENTER,
			vexpand = true
		};

		content.prepend (clamp);

		add_poll_action_button = new Gtk.Button() {
			icon_name = "tuba-plus-large-symbolic",
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			tooltip_text = _("Add Poll"),
			css_classes = {"flat"}
		};
		add_poll_action_button.clicked.connect(add_poll_row_without_title);

		var multi_button = new Gtk.ToggleButton() {
			icon_name = "radio-checked-symbolic",
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			tooltip_text = _("Enable Multiple Choice"),
			css_classes = {"flat"}
		};
		multi_button.bind_property ("active", this, "multiple-choice", GLib.BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			var multi_button_active = src.get_boolean ();
			target.set_boolean (multi_button_active);
			multi_button.icon_name = multi_button_active ? "checkbox-checked-symbolic" : "radio-checked-symbolic";
			multi_button.tooltip_text = multi_button_active ? _("Disable Multiple Choice") : _("Enable Multiple Choice");
			return true;
		});

		var sensitive_media_button = new Gtk.ToggleButton() {
			icon_name = "tuba-eye-open-negative-filled-symbolic",
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			tooltip_text = _("Hide Total Votes"),
			css_classes = {"flat"}
		};
		sensitive_media_button.bind_property ("active", this, "hide-totals", GLib.BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			var sensitive_media_button_active = src.get_boolean ();
			target.set_boolean (sensitive_media_button_active);
			sensitive_media_button.icon_name = sensitive_media_button_active ? "tuba-eye-not-looking-symbolic" : "tuba-eye-open-negative-filled-symbolic";
			sensitive_media_button.tooltip_text = sensitive_media_button_active ? _("Show Total Votes") : _("Hide Total Votes");
			return true;
		});

		bottom_bar.pack_start (add_poll_action_button);
		bottom_bar.pack_start (multi_button);
		bottom_bar.pack_start (sensitive_media_button);

		if (status.poll != null && status.poll.options != null && status.poll.options.size > 0) {
			multi_button.active = status.poll.multiple;

			foreach (var option in status.poll.options) {
				if (option != null) add_poll_row (option);
            }

			install_expires_in (status.poll.expires_at);
		} else {
			add_poll_row ();
			add_poll_row ();
			install_expires_in ();
		}

		bottom_bar.show ();
	}

	private void add_poll_row (string? content = null) {
		var row = new Tuba.PollPage.Poll () {
			title = _("Choice %d").printf (poll_options.size + 1)
		};

		if (content != null) row.text = content;

		poll_options.add (row);
		poll_list.append (row);

		bind_property ("can-delete", row.delete_button, "visible", GLib.BindingFlags.SYNC_CREATE);
		row.deleted.connect(remove_poll_row);
		row.bind_property ("is-valid", this, "is-valid", GLib.BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_boolean (!check_invalid ());

			return true;
		});

		check_poll_items ();
	}

	public bool check_invalid () {
		var any_invalid = false;
		foreach (var t_row in poll_options) {
			any_invalid = !t_row.is_valid;
			if (any_invalid) break;
		}
		return any_invalid;
	}

	private void remove_poll_row (Tuba.PollPage.Poll row) {
		poll_options.remove (row);
		poll_list.remove (row);

		var i = 0;
		foreach (var t_row in poll_options) {
			i++;
			t_row.title = _("Choice %d").printf (i);
		}

		is_valid = !check_invalid ();
		check_poll_items ();
	}

	Expiration[] expirations = {
		new Expiration (_("%d Minutes").printf (5), _("%dm").printf (5), 300),
		new Expiration (_("%d Minutes").printf (30), _("%dm").printf (30), 1800),
		new Expiration (_("%d Hour").printf (1), _("%dh").printf (1), 3600),
		new Expiration (_("%d Hours").printf (6), _("%dh").printf (6), 21600),
		new Expiration (_("%d Hours").printf (12), _("%dh").printf (12), 43200),
		new Expiration (_("%d Day").printf (1), _("%dd").printf (1), 86400),
		new Expiration (_("%d Days").printf (3), _("%dd").printf (3), 259200),
		new Expiration (_("%d Days").printf (7), _("%dd").printf (7), 604800)
	};
	Gtk.DropDown expiration_button;
	protected void install_expires_in (string? expires_at = null) {
		var store = new GLib.ListStore (typeof (Expiration));

		int64 min = accounts.active.instance_info.compat_status_poll_min_expiration;
		int64 max = accounts.active.instance_info.compat_status_poll_max_expiration;

		if (min > 604800) min = 0;
		if (max < 300) max = 604800;

		foreach (var expiration in expirations) {
			if (min <= expiration.value && max >= expiration.value) store.append (expiration);
		}

		expiration_button = new Gtk.DropDown (store, null) {
			expression = new Gtk.PropertyExpression (typeof (Expiration), null, "text"),
			factory = new Gtk.BuilderListItemFactory.from_resource (null, Build.RESOURCES+"gtk/dropdown/expiration_title.ui"),
			list_factory = new Gtk.BuilderListItemFactory.from_resource (null, Build.RESOURCES+"gtk/dropdown/expiration.ui"),
			tooltip_text = _("Expiration"),
			enable_search = false
		};

		if (expires_at != null) {
			var date = new GLib.DateTime.from_iso8601 (expires_at, null);
			var now = new GLib.DateTime.now_local ();
			var delta = date.difference (now);

			uint default_exp_index;
			if (store.find_with_equal_func(new Expiration(null, null, delta / TimeSpan.SECOND), Expiration.compare, out default_exp_index)) {
				expiration_button.selected = default_exp_index;
			}
		}

		add_button (expiration_button);
	}

	public override void on_push () {
		status.poll.options.clear ();
		foreach (var t_row in poll_options) {
			if (t_row.text != "")
				status.poll.options.add (t_row.text);
		}

		status.poll.multiple = multiple_choice;
		status.poll.hide_totals = hide_totals;
	}

	public override void on_modify_req (Json.Builder builder) {
		if (is_valid && this.visible){
			builder.set_member_name ("poll");
			builder.begin_object ();

			builder.set_member_name ("multiple");
			builder.add_boolean_value (status.poll.multiple);

			builder.set_member_name ("hide_totals");
			builder.add_boolean_value (status.poll.hide_totals);

			builder.set_member_name ("expires_in");
			builder.add_int_value (((Expiration) expiration_button.selected_item).value);

			builder.set_member_name ("options");
			builder.begin_array ();
			foreach (var option in status.poll.options) {
				builder.add_string_value (option);
			}
			builder.end_array ();

			builder.end_object ();
		}
	}
}
