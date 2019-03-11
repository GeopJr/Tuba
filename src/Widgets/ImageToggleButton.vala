using Gtk;

public class Tootle.Widgets.ImageToggleButton : ToggleButton {

    public Image icon;
    public IconSize size;

    public ImageToggleButton (string icon_name, IconSize icon_size = IconSize.BUTTON) {
        valign = Align.CENTER;
        size = icon_size;
        icon = new Image.from_icon_name (icon_name, icon_size);
        add (icon);
        show_all ();
    }
    
    public void set_action () {
        can_default = false;
        set_focus_on_click (false);
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
    }
    
}
