using Gtk;

public class Tootle.Widgets.VisibilityPopover: Popover {

	protected RadioButton? group_owner;
	protected MenuButton button;
	protected int i = 0;
	
	public API.Visibility selected { get; set; default = API.Visibility.PUBLIC; }

	protected Box box;

	construct {
		var box = new Box (Orientation.VERTICAL, 8);
		box.margin = 8;
		box.show ();
		add (box);
		
		foreach (API.Visibility item in API.Visibility.all ()){
			var radio = new RadioButton.from_widget (group_owner);
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

}

