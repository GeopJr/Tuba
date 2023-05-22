using Gtk;
using Gdk;

public class Tuba.Widgets.VoteCheckButton : CheckButton {
	public string poll_title { get; set;}

    public VoteCheckButton () {
        Object (
        	align: Gtk.Alignment.CENTER
        );
        this.add_css_class("selection-mode");
    }
}
