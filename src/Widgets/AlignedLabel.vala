using Gtk;

public class AlignedLabel : Gtk.Label {

    public AlignedLabel (string text) {
        label = text;
        halign = Gtk.Align.END;
        //margin_start = 12;
    }

}
