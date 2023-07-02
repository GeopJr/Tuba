using Gtk;
using Gdk;

public class Tuba.Widgets.VoteCheckButton : CheckButton {
	public string poll_title { get; set;}

    construct {
        valign = Align.CENTER;
        css_classes = { "selection-mode" };
    }
}
