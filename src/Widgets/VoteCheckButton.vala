using Gtk;
using Gdk;

public class Tuba.Widgets.VoteCheckButton : CheckButton {
	public string poll_title { get; set;}

    public VoteCheckButton () {
        Object (
            valign: Align.CENTER
        );
        this.add_css_class ("selection-mode");
    }
}
