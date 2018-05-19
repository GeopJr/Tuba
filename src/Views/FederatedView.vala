using Gtk;

public class Tootle.FederatedView : TimelineView {

    public FederatedView () {
        base ("public");
    }
    
    public override string get_icon () {
        return "network-workgroup-symbolic";
    }
    
    public override string get_name () {
        return _("Federated Timeline");
    }

}
