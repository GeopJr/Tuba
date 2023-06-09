public class Tuba.PollPage : ComposerPage {
	public class Poll : Adw.EntryRow {
		public bool is_valid { get; private set; default=false; }
		public Gtk.Button delete_button { get; private set; }

		construct {
			delete_button = new Gtk.Button () {
				icon_name = "tuba-trash-symbolic",
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER,
				css_classes = { "flat", "circular", "error" }
			};

			add_suffix (delete_button);
			changed.connect (() => {
				var text_count = text.char_count ();
				var passed_limit = text_count > accounts.active.instance_info.compat_status_poll_max_characters;
	
				if (passed_limit) {
					add_css_class ("error");
				} else {
					remove_css_class ("error");
				}

				is_valid = !passed_limit && text_count > 0;
			});
		}
	}

	Gee.ArrayList<Tuba.PollPage.Poll> poll_options = new Gee.ArrayList<Tuba.PollPage.Poll>();
	Gtk.ListBox poll_list;
	Gtk.Button add_poll_action_button;
	public bool can_delete { get; private set; default=false; }

	construct {
		title = _("Poll");
		icon_name = "tuba-text-justify-left-symbolic";
	}

	private void check_poll_items () {
		var poll_options_amount = poll_options.size;

		can_delete = poll_options_amount > 2;
		add_poll_action_button.sensitive = poll_options_amount < accounts.active.instance_info.compat_status_poll_max_options;
	}

	public override void on_build (Dialogs.Compose dialog, API.Status status) {
		base.on_build (dialog, status);

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
		add_poll_action_button.clicked.connect(add_poll_row);

		var multi_button = new Gtk.ToggleButton() {
			icon_name = "tuba-eye-open-negative-filled-symbolic",
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			// translators: sensitive as in not safe for work or similar
			tooltip_text = _("Mark media as sensitive"),
			css_classes = {"flat"}
		};

		bottom_bar.pack_start (add_poll_action_button);
		bottom_bar.pack_start (multi_button);

		bottom_bar.show ();

		add_poll_row ();
		add_poll_row ();
	}

	private void add_poll_row () {
		var row = new Tuba.PollPage.Poll () {
			title = _("Choice %d").printf (poll_options.size + 1)
		};

		poll_options.add (row);
		poll_list.append (row);

		bind_property ("can-delete", row.delete_button, "visible", GLib.BindingFlags.SYNC_CREATE);
		row.delete_button.clicked.connect(() => remove_poll_row (row));
		row.bind_property ("is-valid", this, "can-publish", GLib.BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			var any_invalid = false;
			foreach (var t_row in poll_options) {
				any_invalid = !t_row.is_valid;
				if (any_invalid) break;
			}
			target.set_boolean (!any_invalid);

			return true;
		});

		check_poll_items ();
	}

	private void remove_poll_row (Tuba.PollPage.Poll row) {
		poll_options.remove (row);
		poll_list.remove (row);

		var i = 0;
		foreach (var t_row in poll_options) {
			i++;
			t_row.title = _("Choice %d").printf (i);
		}

		check_poll_items ();
	}

}
