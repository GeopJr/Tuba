using Gtk;

public class Tootle.LocalView : Tootle.HomeView {

    public LocalView () {
        base ("public", "?local=true");
    }
    
    public override string get_icon () {
        return "folder-recent-symbolic";
    }
    
    public override string get_name () {
        return "Local Timeline";
    }

}
