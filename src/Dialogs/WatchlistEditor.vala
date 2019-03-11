using Gtk;
using Gee;

public class Tootle.Dialogs.WatchlistEditor : Dialog {

    private static WatchlistEditor dialog;

    private StackSwitcher switcher;
    private MenuButton button_add;
    private Button button_remove;
    private Stack stack;
    private ListStack users;
    private ListStack hashtags;
    private ActionBar actionbar;
    private Popover popover;
    private Grid popover_grid;
    private Entry popover_entry;
    private Button popover_button;

    private const string TIP_USERS = _("You'll be notified when toots from this user appear in your Home timeline.");
    private const string TIP_HASHTAGS = _("You'll be notified when toots with this hashtag appear in any public timelines.");

    private class ModelItem : GLib.Object {
        public string name;

        public ModelItem (string name) {
            this.name = name;
        }
    }

    private class ModelView : ListBoxRow {
        public Label label;
        public ModelView (ModelItem item) {
            label = new Label (item.name);
            label.margin = 6;
            label.halign = Align.START;
            label.justify = Justification.LEFT;
            add (label);
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

        public void update (ArrayList<string> array) {
            array.@foreach (item => {
                model.append (new ModelItem (item));
                return true;
            });
            list.bind_model (model, create_row);
        }

        public ListStack (ArrayList<string> array) {
            model = new Model ();
            list = new ListBox ();
            add (list);
            update (array);
        }
    }

    private void set_tip () {
        var is_user = stack.visible_child_name == "users";
        popover_entry.secondary_icon_tooltip_text = is_user ? TIP_USERS : TIP_HASHTAGS;
    }

    public WatchlistEditor () {
        border_width = 6;
        deletable = false;
        resizable = false;
        transient_for = window;
        title = _("Watchlist");

        users = new ListStack (watchlist.users);
        hashtags = new ListStack (watchlist.hashtags);

        stack = new Stack ();
        stack.transition_type = StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.hexpand = true;
        stack.vexpand = true;
        stack.add_titled (users, "users", _("Users"));
        stack.add_titled (hashtags, "hashtags", _("Hashtags"));

        switcher = new StackSwitcher ();
        switcher.stack = stack;
        switcher.halign = Align.CENTER;
        switcher.margin_bottom = 12;

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
        button_add.popover = popover;
        button_add.clicked.connect (() => set_tip ());

        button_remove = new Button ();
        button_remove.image = new Image.from_icon_name ("list-remove-symbolic", IconSize.BUTTON);
        button_remove.clicked.connect (on_remove);

        actionbar = new ActionBar ();
        actionbar.add (button_add);
        actionbar.add (button_remove);

        var grid = new Grid ();
        grid.attach (stack, 0, 1);
        grid.attach (actionbar, 0, 2);

        var frame = new Frame (null);
        frame.margin_bottom = 6;
        frame.add (grid);
        frame.set_size_request (350, 350);

        var content = get_content_area ();
        content.pack_start (switcher, true, true, 0);
        content.pack_start (frame, true, true, 0);

        add_button (_("_Close"), ResponseType.DELETE_EVENT);
        show_all ();

        response.connect (on_response);
        destroy.connect (() => dialog = null);
    }

    private void on_response (int i) {
        destroy ();
    }

    private void on_remove () {
        var is_hashtag = stack.visible_child_name == "hashtags";
        ListStack stack = is_hashtag ? hashtags : users;
        stack.list.get_selected_rows ().@foreach (_row => {
            var row = _row as ModelView;
            watchlist.remove (row.label.label, is_hashtag);
            watchlist.save ();
            row.destroy ();
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

        var stack = is_hashtag ? hashtags : users;
        stack.list.insert (create_row (new ModelItem (entity)), 0);
    }

    public static void open () {
        if (dialog == null)
            dialog = new WatchlistEditor ();
    }

}
