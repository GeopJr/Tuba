using Gtk;

public class Tootle.ImageToggleButton : Gtk.ToggleButton {

    public Gtk.Image icon;
    public Gtk.IconSize size;

    public ImageToggleButton (string icon_name, Gtk.IconSize icon_size = Gtk.IconSize.SMALL_TOOLBAR) {
        size = icon_size;
        icon = new Gtk.Image.from_icon_name (icon_name, icon_size);
        add (icon);
        show_all ();
    }
    
    public void set_action () {
        can_default = false;
        set_focus_on_click (false);
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
    }
    
}
