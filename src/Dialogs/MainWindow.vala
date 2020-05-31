using Gtk;
using Gdk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/main.ui")]
public class Tootle.Dialogs.MainWindow: Gtk.Window, ISavedWindow {

    [GtkChild]
    protected Stack view_stack;
    [GtkChild]
    protected Stack timeline_stack;

    [GtkChild]
    protected HeaderBar header;
    [GtkChild]
    protected Button back_button;
    [GtkChild]
    protected Button compose_button;
    [GtkChild]
    protected Hdy.ViewSwitcher timeline_switcher;
    [GtkChild]
    protected Widgets.AccountsButton accounts_button;

    Views.Base? last_view = null;

    construct {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource (@"$(Build.RESOURCES)app.css");
        StyleContext.add_provider_for_screen (Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        back_button.clicked.connect (() => back ());
        Desktop.set_hotkey_tooltip (back_button, _("Back"), app.ACCEL_BACK);

        compose_button.clicked.connect (() => new Dialogs.Compose ());
        Desktop.set_hotkey_tooltip (compose_button, _("Compose"), app.ACCEL_NEW_POST);

        timeline_switcher.stack = timeline_stack;
        timeline_switcher.valign = Align.FILL;
        timeline_stack.notify["visible-child"].connect (on_timeline_changed);

        add_timeline_view (new Views.Home (), app.ACCEL_TIMELINE_0, 0);
        add_timeline_view (new Views.Notifications (), app.ACCEL_TIMELINE_1, 1);
        add_timeline_view (new Views.Local (), app.ACCEL_TIMELINE_2, 2);
        add_timeline_view (new Views.Federated (), app.ACCEL_TIMELINE_3, 3);

        settings.bind_property ("dark-theme", Gtk.Settings.get_default (), "gtk-application-prefer-dark-theme", BindingFlags.SYNC_CREATE);

        button_press_event.connect (on_button_press);
        update_header ();
        restore_state ();
    }

    public MainWindow (Gtk.Application app) {
        Object (
            application: app,
            icon_name: Build.DOMAIN,
            resizable: true,
            window_position: WindowPosition.CENTER
        );

        if (accounts.is_empty ())
            open_view (new Views.NewAccount (false));
    }

    public int get_visible_id () {
        return int.parse (view_stack.get_visible_child_name ());
    }

    public bool open_view (Views.Base widget) {
        var i = get_visible_id ();
        i++;
        widget.stack_pos = i;
        widget.show ();
        view_stack.add_named (widget, i.to_string ());
        view_stack.set_visible_child_name (i.to_string ());
        update_header ();
        return true;
    }

    public bool back () {
        var i = get_visible_id ();
        if (i == 0)
            return false;

        var child = view_stack.get_child_by_name (i.to_string ());
        view_stack.set_visible_child_name ((i-1).to_string ());
        child.destroy ();
        update_header ();
        return true;
    }

    public void reopen_view (int view_id) {
        var i = get_visible_id ();
        while (i != view_id && view_id != 0) {
            back ();
            i = get_visible_id ();
        }
    }

    public override bool delete_event (EventAny event) {
        destroy.connect (() => {
            if (!settings.work_in_background || accounts.is_empty ())
                app.remove_window (window_dummy);
            window = null;
        });
        return false;
    }

    public void switch_timeline (int32 num) {
        timeline_stack.visible_child_name = num.to_string ();
    }

    bool on_button_press (EventButton ev) {
        if (ev.button == 8)
            return back ();
        return false;
    }

    void add_timeline_view (Views.Base view, string[] accelerators, int32 num) {
        timeline_stack.add_titled (view, num.to_string (), view.label);
        timeline_stack.child_set_property (view, "icon-name", view.icon);
        view.notify["needs-attention"].connect (() => {
            timeline_stack.child_set_property (view, "needs-attention", view.needs_attention);
        });
    }

    void update_header () {
        bool primary_mode = get_visible_id () == 0;
        timeline_switcher.sensitive = primary_mode;
        timeline_switcher.opacity = primary_mode ? 1 : 0; //Prevent HeaderBar height jitter
        compose_button.visible = primary_mode;
        back_button.visible = !primary_mode;
    }

    void on_timeline_changed (ParamSpec spec) {
        var view = timeline_stack.visible_child as Views.Base;

        if (last_view != null)
            last_view.current = false;

        if (view != null) {
            view.current = true;
            last_view = view;
        }
    }

}
