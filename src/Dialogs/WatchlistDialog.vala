using Gtk;
using Tootle;

public class Tootle.WatchlistDialog : Gtk.Dialog {

    private static WatchlistDialog dialog;

    private HeaderBar header;
    private StackSwitcher switcher;
    private Gtk.MenuButton button_add;
    private Stack stack;
    private ListStack users;
    private ListStack hashtags;
    
    private Popover popover;
    private Grid popover_grid;
    private Entry popover_entry;
    private Button popover_button;

    private const string TIP_USERS = _("You'll be notified when toots from this user appear in your Home timeline.");
    private const string TIP_HASHTAGS = _("You'll be notified when toots with this hashtag appear in any public timelines.");

    private class ModelItem : GLib.Object {
        public string name;
        public bool is_hashtag;
        
        public ModelItem (string name, bool is_hashtag) {
            this.name = name;
            this.is_hashtag  = is_hashtag;
        }
    }
    
    private class ModelView : ListBoxRow {
        private Box box;
        private Button button_remove;
        private Label label;
        private bool is_hashtag;
        
        public ModelView (ModelItem item) {
            is_hashtag = item.is_hashtag;
            box = new Box (Orientation.HORIZONTAL, 0);
            box.margin = 6;
            label = new Label (item.name);
            label.vexpand = true;
            label.valign = Align.CENTER;
            label.justify = Justification.LEFT;
            button_remove = new Button.from_icon_name ("list-remove-symbolic", IconSize.BUTTON);
            button_remove.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            button_remove.clicked.connect (() => {
                watchlist.remove (label.label, is_hashtag);
                watchlist.save ();
                destroy ();
            });
            
            box.pack_start (label, false, false, 0);
            box.pack_end (button_remove, false, false, 0);
            add (box);
            show_all ();
        }
    }

    private class Model : GLib.ListModel, GLib.Object {
        private GenericArray<ModelItem> items = new GenericArray<ModelItem> ();
        
        public GLib.Type get_item_type () {
            return typeof (ModelItem);
        }

        public uint get_n_items () {
            return items.length;
        }

        public GLib.Object? get_item (uint position) {
            return items.@get ((int)position);
        }

        public void append (ModelItem item) {
            this.items.add (item);
        }
    
    }

    public static Widget create_row (GLib.Object obj) {
        var item = (ModelItem) obj;
        return new ModelView (item);
    }

    private class ListStack : ScrolledWindow {
        public Model model;
        public ListBox list;
        private bool is_hashtags;
        
        public void update () {
            if (is_hashtags)
                watchlist.hashtags.@foreach (item => {
                    model.append (new ModelItem (item, true));
                    return true;
                });
            else
                watchlist.users.@foreach (item => {
                    model.append (new ModelItem (item, false));
                    return true;
                });
            
            list.bind_model (model, create_row);
        }
        
        public ListStack (bool is_hashtags) {
            this.is_hashtags = is_hashtags;
            model = new Model ();
            list = new ListBox ();
            add (list);
            update ();
        }
    }

    private void set_tip () {
        var is_user = stack.visible_child_name == "users";
        popover_entry.secondary_icon_tooltip_text = is_user ? TIP_USERS : TIP_HASHTAGS;
    }

    public WatchlistDialog () {
        deletable = true;
        resizable = false;
        transient_for = window;
        
        var content = get_content_area ();
        
        stack = new Stack ();
        stack.transition_type = StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.hexpand = true;
        stack.vexpand = true;
        
        users = new ListStack (false);
        hashtags = new ListStack (true);
        
        stack.add_titled (users, "users", _("Users"));
        stack.add_titled (hashtags, "hashtags", _("Hashtags"));
        stack.set_size_request (350, 400);
        content.pack_start (stack, true, true, 0);
        
        popover_entry = new Entry ();
        popover_entry.hexpand = true;
        popover_entry.secondary_icon_name = "dialog-information-symbolic";
        popover_entry.secondary_icon_activatable = false;
        popover_entry.activate.connect (() => submit ());
        
        popover_button = new Button.with_label (_("Add"));
        popover_button.halign = Align.END;
        popover_button.margin_start = 6;
        popover_button.clicked.connect (() => submit ());
        
        popover_grid = new Grid ();
        popover_grid.margin = 6;
        popover_grid.attach (popover_entry, 0, 0);
        popover_grid.attach (popover_button, 1, 0);
        popover_grid.show_all ();
        
        popover = new Popover (null);
        popover.add (popover_grid);
        
        button_add = new MenuButton ();
        button_add.image = new Image.from_icon_name ("list-add-symbolic", IconSize.BUTTON);
        button_add.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        button_add.popover = popover;
        button_add.clicked.connect (() => set_tip ());
        
        switcher = new StackSwitcher ();
        switcher.stack = stack;
        switcher.halign = Align.CENTER;
        
        header = new HeaderBar ();
        header.show_close_button = true;
        header.pack_start (button_add);
        header.set_custom_title (switcher);
        set_titlebar (header);
        
        show_all ();
        
        destroy.connect (() => dialog = null);
    }
    
    private void submit () {
        if (popover_entry.text_length < 1)
            return;
        
        var is_hashtag = stack.visible_child_name == "hashtags";
        var entity = popover_entry.text
            .replace ("#", "")
            .replace (" ", "");
        
        watchlist.add (entity, is_hashtag);
        watchlist.save ();
        button_add.active = false;
        
        if (is_hashtag)
            hashtags.list.insert (create_row (new ModelItem (entity, true)), 0);
        else
            users.list.insert (create_row (new ModelItem (entity, false)), 0);
    }

    public static void open () {
        if (dialog == null)
            dialog = new WatchlistDialog ();
    }

}
