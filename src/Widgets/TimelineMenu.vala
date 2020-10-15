using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/timeline_menu.ui")]
public class Tootle.Widgets.TimelineMenu : MenuButton {

	[GtkChild]
	public Label title;
	[GtkChild]
	public Label subtitle;

	public TimelineMenu (string id) {
		var builder = new Builder.from_resource (@"$(Build.RESOURCES)ui/menus.ui");
		menu_model = builder.get_object (id) as MenuModel;
	}

}
