using Gtk;

public class Tuba.EditorPage : ComposerPage {

	protected int64 char_limit { get; set; default = 500; }
	protected int64 remaining_chars { get; set; default = 0; }
	public bool can_publish { get; set; default = false; }

	construct {
		//  translators: "Text" as in text-based input
		title = _("Text");
		icon_name = "document-edit-symbolic";

		var char_limit_api = accounts.active.instance_info.compat_status_max_characters;
		if (char_limit_api > 0)
			char_limit = char_limit_api;
		remaining_chars = char_limit;
	}

	public override void on_build (Dialogs.Compose dialog, API.Status status) {
		base.on_build (dialog, status);

		install_editor ();
		install_overlay();
		install_visibility (status.visibility);
		install_cw ();
		install_emoji_picker();

		validate ();
	}

	protected virtual signal void recount_chars () {}

	protected void validate () {
		recount_chars ();
	}

	public override void on_pull () {
		populate_editor ();
	}

	public override void on_push () {
		status.content = editor.buffer.text;
		status.sensitive = cw_button.active;
		if (status.sensitive) {
			status.spoiler_text = cw_entry.text;
		}

		var instance_visibility = (visibility_button.selected_item as InstanceAccount.Visibility);
		if (visibility_button != null && visibility_button.selected_item != null && instance_visibility != null)
			status.visibility = instance_visibility.id;
	}

	public override void on_modify_req (Request req) {
		if (can_publish)
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
			remaining_chars = char_limit;
		});
		recount_chars.connect_after (() => {
			placeholder.visible = remaining_chars == char_limit;
			char_counter.label = remaining_chars.to_string ();
			if (remaining_chars < 0) {
				char_counter.add_css_class ("error");
				can_publish = false;
			} else {
				char_counter.remove_css_class ("error");
				can_publish = remaining_chars != char_limit;
			}
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
		//  content.prepend (editor);

		char_counter = new Label (char_limit.to_string ()) {
			margin_end = 6,
			tooltip_text = _("Characters Left")
		};
		char_counter.add_css_class ("heading");
		bottom_bar.pack_end (char_counter);
		editor.buffer.changed.connect (validate);
	}

	protected Overlay overlay;
	protected Label placeholder;

	protected void install_overlay() {
		overlay = new Overlay();
		placeholder = new Label(_("What's on your mind?")) {
			valign = Align.START,
			halign = Align.START,
			justify = Justification.FILL,
			margin_top = 6,
			margin_start = 6,
			wrap = true,
			sensitive = false
		};
		
		overlay.add_overlay(placeholder);
		overlay.child = editor;
		content.prepend(overlay);
	}

	protected void populate_editor () {
		editor.buffer.text = dialog.status.content;
	}

	protected EmojiChooser emoji_picker;
	protected void install_emoji_picker () {
		emoji_picker = new EmojiChooser();
		var emoji_button = new MenuButton() {
			icon_name = "tuba-smile-symbolic",
			popover = emoji_picker,
			tooltip_text = _("Emoji Picker")
		};

		add_button(emoji_button);

		emoji_picker.emoji_picked.connect(on_emoji_picked);
	}

	protected void on_emoji_picked(string emoji_unicode) {
		editor.buffer.insert_at_cursor(emoji_unicode, emoji_unicode.data.length);
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
			icon_name = "tuba-warning-symbolic",
			tooltip_text = _("Content Warning")
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

	protected void install_visibility (string default_visibility = "public") {
		visibility_button = new DropDown (accounts.active.visibility_list, null) {
			expression = new PropertyExpression (typeof (InstanceAccount.Visibility), null, "name"),
			factory = new BuilderListItemFactory.from_resource (null, Build.RESOURCES+"gtk/dropdown/icon.ui"),
			list_factory = new BuilderListItemFactory.from_resource (null, Build.RESOURCES+"gtk/dropdown/full.ui"),
			tooltip_text = _("Post Privacy")
		};

		uint default_visibility_index;
		if (accounts.active.visibility_list.find(accounts.active.visibility[default_visibility], out default_visibility_index)) {
			visibility_button.selected = default_visibility_index;
		}

		add_button (visibility_button);
		add_button (new Gtk.Separator (Orientation.VERTICAL));
	}

}
