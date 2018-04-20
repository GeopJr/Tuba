using Gtk;

public class Tootle.StatusView : Tootle.AbstractView {

    Gtk.Box view;
    Gtk.ScrolledWindow scroll;

    construct {
        view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        view.hexpand = true;
        view.valign = Gtk.Align.START;

        scroll = new Gtk.ScrolledWindow (null, null);
        scroll.hexpand = true;
        scroll.vexpand = true;
        scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroll.add (view);
        add (scroll);
    }

    public StatusView (Status status) {
        base (false);
        
        var widget = new StatusWidget(status);
        widget.rebind (status);
        widget.content.selectable = true;
        view.pack_start (widget, false, false, 0);
        
        show_all();
    }

}


