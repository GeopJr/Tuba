using Gtk;
using Granite;

public class Tootle.AddAccountView : Tootle.AbstractView {

    public Stack stack;
    GridInstance grid_instance;
    GridCode grid_code;
    
    protected class GridInstance : Grid{
        Image image;
        public Button button_next;
        public Entry entry;
    
        construct{
            column_spacing = 12;
            row_spacing = 6;
            hexpand = true;
            halign = Gtk.Align.CENTER;
            
            image = new Image.from_resource ("/com/github/bleakgrey/tootle/elephant1.png");
            image.halign = Gtk.Align.CENTER;
            image.hexpand = true;
            image.margin_bottom = 24;
            
            entry = new Entry ();
            entry.text = "https://myinstance.com/";
            entry.set_placeholder_text ("https://myinstance.com/");
            entry.width_chars = 30;
             
            button_next = new Button.with_label ("Next");
            button_next.halign = Gtk.Align.END;
            
            var register = new Label ("<a href=\"https://joinmastodon.org/\">What's an instance?</a>");
            register.halign = Gtk.Align.END;
            register.set_use_markup (true);
            
            attach (image, 0, 1, 2, 1);
            attach (new AlignedLabel ("Instance:"), 0, 2, 1, 1);
            attach (entry, 1, 2, 1, 1);
            attach (button_next, 0, 3, 2, 1);
            attach (register, 0, 4, 2, 1);
        }
    
        public GridInstance(){}
    }
    
    protected class GridCode : Grid{
        Granite.Widgets.Avatar image;
        public Button button_back;
        public Button button_next;
        public Entry code;
    
        construct{
            column_spacing = 12;
            row_spacing = 6;
            hexpand = true;
            halign = Gtk.Align.CENTER;
            valign = Gtk.Align.CENTER;
            
            image = new Granite.Widgets.Avatar.with_default_icon (128);
            image.halign = Gtk.Align.CENTER;
            image.hexpand = true;
            image.margin_bottom = 24;
            
            code = new Entry ();
            code.width_chars = 30;
            
            button_next = new Button.with_label ("Add Account");
            button_next.halign = Gtk.Align.END;
            
            button_back = new Button.with_label ("Back");
            button_back.halign = Gtk.Align.START;
            
            attach (image, 0, 1, 2, 1);
            attach (new AlignedLabel ("Authorization Code:"), 0, 2, 1, 1);
            attach (code, 1, 2, 1, 1);
            attach (button_back, 0, 3, 1, 1);
            attach (button_next, 1, 3, 1, 1);
        }
    
        public GridCode(){}
    }
    
    

    construct {
        stack = new Stack ();
        stack.valign = Gtk.Align.CENTER;
        stack.vexpand = true;
        stack.transition_type = StackTransitionType.SLIDE_LEFT_RIGHT;
        
        grid_instance = new GridInstance ();
        grid_instance.button_next.clicked.connect(on_next_click);
        
        grid_code = new GridCode ();
        grid_code.button_back.clicked.connect(() => stack.set_visible_child_name ("instance"));
        grid_code.button_next.clicked.connect(on_add_click);
        
        var header1 = new Gtk.Label ("Enter Your Instance URL:");
        header1.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header1.halign = Gtk.Align.CENTER;
        header1.hexpand = true;
        
        stack.add_named (grid_instance, "instance");
        stack.add_named (grid_code, "code");
        
        view.add (stack);
        show_all ();
    }

    public AddAccountView () {
        base ();
    }
    
    public override string get_name () {
        return "add_account";
    }
    
    private void on_next_click(){
        Tootle.settings.clear_account ();
        Tootle.settings.instance_url = grid_instance.entry.text;
        grid_instance.sensitive = false; 
        
        if(!Tootle.accounts.has_client_tokens ()){
            var msg = Tootle.accounts.request_client_tokens ();
            msg.finished.connect(() => {
                grid_instance.sensitive = true;
                stack.set_visible_child_name ("code");
            });
        }
        else{
            grid_instance.sensitive = true;
            stack.set_visible_child_name ("code");
            Tootle.accounts.request_auth_code (Tootle.settings.client_id);
        }
    }
    
    private void on_add_click (){
        var code = grid_code.code.text;
        Tootle.accounts.try_auth (code);
    }

}
