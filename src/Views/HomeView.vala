public class Tootle.HomeView : TimelineView {

    public HomeView () {
        base ("home");
    }
    
    public override string get_icon () {
        return "user-home-symbolic";
    }
    
    public override string get_name () {
        return _("Home");
    }
    
    public override Soup.Message? get_stream () {
        return accounts.formal.get_stream ();
    }

}
