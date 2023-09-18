public class Tuba.Widgets.VoteCheckButton : Gtk.CheckButton {
	public string poll_title { get; set;}

    construct {
        valign = Gtk.Align.CENTER;
        css_classes = { "selection-mode" };
    }
}
