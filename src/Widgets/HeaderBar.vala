using Gtk;

public class Tootle.HeaderBar : Gtk.HeaderBar{

    public Granite.Widgets.ModeButton button_mode;
    AccountsButton button_accounts;
    Spinner spinner;
    Button button_toot;
    Button button_back;
    
    private int last_tab = 0;
    
    construct {
        spinner = new Spinner ();
        spinner.active = true;

        button_accounts = new AccountsButton ();
        
        button_back = new Button ();
        button_back.label = _("Back");
        button_back.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);
        button_back.clicked.connect (() => {
            var primary_stack = Tootle.window.primary_stack;
            var i = int.parse (primary_stack.get_visible_child_name ());
            primary_stack.set_visible_child_name ((i-1).to_string ());
            
            var child = primary_stack.get_child_by_name (i.to_string ());
            child.destroy ();
            
            var is_root = primary_stack.get_visible_child_name () == "0";
            update (is_root);
        });
        
        button_toot = new Button ();
        button_toot.tooltip_text = "Toot";
        button_toot.image = new Gtk.Image.from_icon_name ("edit-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        button_toot.clicked.connect (() => PostDialog.open ());

        button_mode = new Granite.Widgets.ModeButton ();
        button_mode.get_style_context ().add_class ("mode");
        button_mode.mode_changed.connect(widget => {
            last_tab = button_mode.selected;
            Tootle.window.secondary_stack.set_visible_child_name(widget.tooltip_text);
        });
        button_mode.show ();
        
        Tootle.network.started.connect (() => spinner.show ());
        Tootle.network.finished.connect (() => spinner.hide ());
        
        pack_start (button_back);
        pack_start (button_toot);
        pack_end (button_accounts);
        pack_end (spinner);
    }

    public HeaderBar () {
        custom_title = button_mode;
        show_close_button = true;
        show ();
        button_mode.valign = Gtk.Align.FILL;
    }
    
    public void update (bool primary_mode, bool hide_all = false){
        button_mode.set_active (last_tab);
        if (hide_all){
            //button_mode.opacity = 0;
            //button_mode.sensitive = false;
            button_mode.hide ();
            button_toot.hide ();
            button_back.hide ();
            button_accounts.hide ();
            return;
        }
        //button_mode.opacity = primary_mode ? 1 : 0;
        //button_mode.sensitive = primary_mode ? true : false;
        button_mode.set_visible (primary_mode);
        button_toot.set_visible (primary_mode);
        button_back.set_visible (!primary_mode);
        button_accounts.set_visible (true);
    }

}
