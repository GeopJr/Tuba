using Gtk;

public class Tootle.Widgets.AlignedLabel : Label {

    public AlignedLabel (string text) {
        label = text;
        halign = Align.END;
        //margin_start = 12;
    }

}
