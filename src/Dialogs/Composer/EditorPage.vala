using Gtk;

public class Tootle.EditorPage : ComposerPage {

	protected uint char_limit { get; set; default = 500; } //TODO: Ask the instance to get this value
	protected int remaining_chars { get; set; default = 0; }

	construct {
		title = _("Text");
		icon_name = "document-edit-symbolic";
	}

	public override void on_build (Dialogs.Compose dialog, API.Status status) {
		base.on_build (dialog, status);

		install_editor ();
		populate_editor ();
		install_visibility ();
		install_cw ();

		validate ();
	}

	protected virtual signal void recount_chars () {}

	protected void validate () {
		recount_chars ();
	}

	public override void on_sync () {
		warning ("syncing");

		status.content = editor.buffer.text;
		status.sensitive = cw_button.active;
		if (status.sensitive) {
			status.spoiler_text = cw_entry.text;
		}

		status.visibility = (visibility_button.selected_item as InstanceAccount.Visibility).id;
	}

	public override void on_modify_req (Request req) {
		req.with_form_data ("status", status.content);
		req.with_form_data ("visibility", status.visibility);

		if (dialog.status.in_reply_to_id != null)
			req.with_form_data ("in_reply_to_id", dialog.status.in_reply_to_id);
		if (dialog.status.in_reply_to_account_id != null)
			req.with_form_data ("in_reply_to_account_id", dialog.status.in_reply_to_account_id);

		if (cw_button.active) {
			req.with_form_data ("sensitive", "true");
			req.with_form_data ("spoiler_text", status.spoiler_text);
		}
	}



	protected TextView editor;
	protected Label char_counter;

	protected void install_editor () {
		recount_chars.connect (() => {
			remaining_chars = (int) char_limit;
		});
		recount_chars.connect_after (() => {
			char_counter.label = remaining_chars.to_string ();
			if (remaining_chars < 0)
				char_counter.add_css_class ("error");
			else
				char_counter.remove_css_class ("error");
		});

		editor = new TextView () {
			vexpand = true,
			hexpand = true,
			top_margin = 6,
			right_margin = 6,
			bottom_margin = 6,
			left_margin = 6,
			pixels_below_lines = 6,
			accepts_tab = false,
			wrap_mode = WrapMode.WORD_CHAR
		};
		recount_chars.connect (() => {
			remaining_chars -= editor.buffer.get_char_count ();
		});
		content.prepend (editor);

		char_counter = new Label (char_limit.to_string ()) {
			margin_end = 6
		};
		char_counter.add_css_class ("heading");
		bottom_bar.pack_end (char_counter);
		editor.buffer.changed.connect (validate);
	}

	protected void populate_editor () {
		editor.buffer.text = dialog.status.content;
	}



	protected ToggleButton cw_button;
	protected Entry cw_entry;

	protected void install_cw () {
		cw_entry = new Gtk.Entry () {
			placeholder_text = _("Write your warning here"),
			margin_top = 6,
			margin_end = 6,
			margin_start = 6
		};
		cw_entry.buffer.inserted_text.connect (validate);
		cw_entry.buffer.deleted_text.connect (validate);
		var revealer = new Gtk.Revealer () {
			child = cw_entry
		};
		revealer.add_css_class ("view");
		content.prepend (revealer);

		cw_button = new ToggleButton () {
			icon_name = "dialog-warning-symbolic",
			tooltip_text = _("Spoiler Warning")
		};
		cw_button.toggled.connect (validate);
		cw_button.bind_property ("active", revealer, "reveal_child", GLib.BindingFlags.SYNC_CREATE);
		add_button (cw_button);

		recount_chars.connect (() => {
			if (cw_button.active)
				remaining_chars -= (int) cw_entry.buffer.length;
		});
	}



	protected DropDown visibility_button;

	protected void install_visibility () {
		visibility_button = new DropDown (accounts.active.visibility_list, null) {
			expression = new PropertyExpression (typeof (InstanceAccount.Visibility), null, "name"),
			factory = new BuilderListItemFactory.from_resource (null, Build.RESOURCES+"gtk/dropdown/icon.ui"),
			list_factory = new BuilderListItemFactory.from_resource (null, Build.RESOURCES+"gtk/dropdown/full.ui")
		};
		add_button (visibility_button);
		add_button (new Gtk.Separator (Orientation.VERTICAL));
	}

}
