using Gtk;

public class Tootle.AccountsButton : Gtk.MenuButton{

    Granite.Widgets.Avatar avatar;
    Gtk.Grid grid;
    Gtk.Popover menu;

    construct{
        //var iconfile = "/var/lib/AccountsService/icons/blue";
        avatar = new Granite.Widgets.Avatar.with_default_icon (24);
        avatar.set_tooltip_text (_("Account Options"));
        avatar.button_press_event.connect(event => {
            return false;
        });
    
        var item_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        item_separator.hexpand = true;
        item_separator.margin_top = 6;
    
        var item_settings = new Gtk.ModelButton ();  
        item_settings.text = _("Settings");  
    
        grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.width_request = 200;
        grid.attach(item_separator, 0, 1, 1, 1);
        grid.attach(item_settings, 0, 2, 1, 1);
        grid.show_all ();
        
        menu = new Gtk.Popover (null);
        menu.add (grid);

        get_style_context ().add_class ("button_avatar");
        popover = menu;
        add(avatar);
        show_all ();
    }

    public AccountsButton(){
        Object();
    }

}
