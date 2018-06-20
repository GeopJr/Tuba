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
    
    protected override bool is_public () {
        return true;
    }
    
    public override Soup.Message? get_stream () {
        var url = "%s/api/v1/streaming/?stream=public&access_token=%s".printf (accounts.formal.instance, accounts.formal.token);
        return new Soup.Message("GET", url);
    }

}
