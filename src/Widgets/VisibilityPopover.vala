using Gtk;

public class Tootle.Widgets.VisibilityPopover: Popover {

	public API.Visibility selected { get; set; default = API.Visibility.PUBLIC; }

	RadioButton? group_owner;
	MenuButton button;

	construct {
		var box = new Box (Orientation.VERTICAL, 8);
		box.margin = 8;
		box.show ();
		add (box);

		int i = 0;
		foreach (API.Visibility item in API.Visibility.all ()){
			var radio = new RadioButton.from_widget (group_owner);
			radio.set_data ("i", (int) item);
			if (group_owner == null)
				group_owner = radio;

			box.pack_start (radio, true, true, 0);
			radio.toggled.connect (() => {
				selected = item;
				popdown ();
			});

			var label = new Label (@"<b>$(item.get_name())</b>\n$(item.get_desc())");
			label.use_markup = true;
			label.xalign = 0;
			label.margin_start = 8;
			radio.add (label);

			i++;
		}

		box.show_all ();
	}

	public VisibilityPopover.with_button (MenuButton w) {
		button = w;
		button.popover = this;
	}

	public void invalidate () {
		unowned var group = group_owner.get_group ();
		group.@foreach (w => {
			int i = w.get_data ("i");
			if (i == (int) selected)
				w.active = true;
		});
	}

}

