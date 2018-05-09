using Gtk;

public class Tootle.LocalView : Tootle.HomeView {

    public LocalView () {
        base ("public");
    }
    
    public override string get_icon () {
        return "folder-recent-symbolic";
    }
    
    public override string get_name () {
        return _("Local Timeline");
    }
    
    public override string get_url (){
        string url = base.get_url ();
        url += "&local=true";
        return url;
    }

}
