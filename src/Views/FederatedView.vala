using Gtk;

public class Tootle.FederatedView : Tootle.HomeView {

    public FederatedView () {
        base ("public");
    }
    
    public override string get_icon () {
        return "network-workgroup-symbolic";
    }
    
    public override string get_name () {
        return "Federated Timeline";
    }

}
