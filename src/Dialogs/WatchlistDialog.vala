using Gtk;
using Tootle;

public class Tootle.WatchlistDialog : Gtk.Window {

    private static WatchlistDialog dialog;

    private Gtk.HeaderBar header;
    private Gtk.StackSwitcher switcher;
    private Gtk.MenuButton button_add;
    private Gtk.Stack stack;
    private ListStack users;
    private ListStack hashtags;
    
    private Gtk.Popover popover;
    private Gtk.Grid popover_grid;
    private Gtk.Entry popover_entry;
    private Gtk.Button popover_button;

    private const string TIP_USERS = _("You'll be notified when toots from specific users appear in your Home timeline.");
    private const string TIP_HASHTAGS = _("You'll be notified when toots with specific hashtags are posted in any public timelines.");

    private class ModelItem : GLib.Object {
        public string name;
        public bool is_hashtag;
        
        public ModelItem (string name, bool is_hashtag) {
            this.name = name;
            this.is_hashtag  = is_hashtag;
        }
    }
    
    private class ModelView : Gtk.ListBoxRow {
        private Gtk.Box box;
        private Gtk.Button button_remove;
        private Gtk.Label label;
        private bool is_hashtag;
        
        public ModelView (ModelItem item) {
            is_hashtag = item.is_hashtag;
            box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.margin = 6;
            label = new Gtk.Label (item.name);
            label.vexpand = true;
            label.valign = Gtk.Align.CENTER;
            label.justify = Gtk.Justification.LEFT;
            button_remove = new Gtk.Button.from_icon_name ("list-remove-symbolic", Gtk.IconSize.BUTTON);
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

    private class ListStack : Gtk.ScrolledWindow {
        public Model model;
        public Gtk.ListBox list;
        private bool is_hashtags;
        
        public void update () {
            if (is_hashtags)
                watchlist.hashtags.@foreach (item => {
                    model.append (new ModelItem (item, true));
                });
            else
                watchlist.users.@foreach (item => {
                    model.append (new ModelItem (item, false));
                });
            
            list.bind_model (model, create_row);
        }
        
        public ListStack (bool is_hashtags) {
            this.is_hashtags = is_hashtags;
            model = new Model ();
            list = new Gtk.ListBox ();
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
        resizable = true;
        transient_for = window;
        
        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.hexpand = true;
        stack.vexpand = true;
        
        users = new ListStack (false);
        hashtags = new ListStack (true);
        
        stack.add_titled (users, "users", _("Users"));
        stack.add_titled (hashtags, "hashtags", _("Hashtags"));
        stack.set_size_request (400, 300);
        
        popover_entry = new Gtk.Entry ();
        popover_entry.hexpand = true;
        popover_entry.secondary_icon_name = "dialog-information-symbolic";
        popover_entry.secondary_icon_activatable = false;
        popover_entry.activate.connect (() => submit ());
        
        popover_button = new Gtk.Button.with_label (_("Add"));
        popover_button.halign = Gtk.Align.END;
        popover_button.margin_left = 8;
        popover_button.clicked.connect (() => submit ());
        
        popover_grid = new Gtk.Grid ();
        popover_grid.margin = 8;
        popover_grid.attach (popover_entry, 0, 0);
        popover_grid.attach (popover_button, 1, 0);
        popover_grid.show_all ();
        
        popover = new Gtk.Popover (null);
        popover.add (popover_grid);
        
        button_add = new Gtk.MenuButton ();
        button_add.image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON);
        button_add.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        button_add.popover = popover;
        button_add.clicked.connect (() => set_tip ());
        
        switcher = new StackSwitcher ();
        switcher.stack = stack;
        switcher.halign = Gtk.Align.CENTER;
        
        header = new Gtk.HeaderBar ();
        header.show_close_button = true;
        header.pack_start (button_add);
        header.set_custom_title (switcher);
        set_titlebar (header);
        
        add (stack);
        show_all ();
        
        destroy.connect (() => {
            dialog = null;
        });
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
