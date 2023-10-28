[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/new_composer.ui")]
public class Tuba.Dialogs.NewCompose : Adw.Window {
	[GtkChild] private unowned Gtk.Label counter_label;
	[GtkChild] private unowned Gtk.Button post_btn;
	[GtkChild] private unowned Gtk.Box btns_box;
	[GtkChild] private unowned Gtk.Grid grid;

	[GtkChild] private unowned Gtk.MenuButton native_emojis_button;
	[GtkChild] private unowned Gtk.MenuButton custom_emojis_button;

	private bool _is_narrow = false;
	public bool is_narrow {
		get {
			return _is_narrow;
		}
		set {
			Gtk.GridLayout layout_manager = (Gtk.GridLayout) grid.get_layout_manager ();
			Gtk.GridLayoutChild counter_layout_child = (Gtk.GridLayoutChild) layout_manager.get_layout_child (counter_label);
			Gtk.GridLayoutChild post_layout_child = (Gtk.GridLayoutChild) layout_manager.get_layout_child (post_btn);
			Gtk.GridLayoutChild btns_layout_child = (Gtk.GridLayoutChild) layout_manager.get_layout_child (btns_box);

			if (value) {
				post_layout_child.column = 1;
				post_layout_child.row = 1;
				post_layout_child.row_span = 1;

				counter_layout_child.row = 0;
				counter_layout_child.column = 1;

				btns_layout_child.column_span = 1;

				counter_label.margin_end = 10;
			} else {
				post_layout_child.column = 2;
				post_layout_child.row = 0;
				post_layout_child.row_span = 2;

				counter_layout_child.row = 1;
				counter_layout_child.column = 1;

				btns_layout_child.column_span = 2;

				counter_label.margin_end = 0;
			}

			_is_narrow = value;
		}
	}

	construct {
		var condition = new Adw.BreakpointCondition.length (
			Adw.BreakpointConditionLengthType.MAX_WIDTH,
			400, Adw.LengthUnit.SP
		);
		var breakpoint = new Adw.Breakpoint (condition);
		breakpoint.add_setter (this, "is-narrow", true);
		add_breakpoint (breakpoint);

		transient_for = app.main_window;

		var emoji_picker = new Gtk.EmojiChooser ();
		native_emojis_button.popover = emoji_picker;

		if (accounts.active.instance_emojis?.size > 0) {
			var custom_emoji_picker = new Widgets.CustomEmojiChooser ();
			custom_emojis_button.popover = custom_emoji_picker;
		}
	}

	public NewCompose (API.Status template = new API.Status.empty ()) {
		Object ();
		present ();
	}
}
