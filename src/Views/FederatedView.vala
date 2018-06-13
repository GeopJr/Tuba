public class Tootle.FederatedView : TimelineView {

    public FederatedView () {
        base ("public");
        notificator = new Notificator (get_stream ());
        notificator.status_added.connect ((ref status) => {
            if (settings.live_updates_public)
                on_status_added (ref status);
        });
    }
    
    public override string get_icon () {
        return "network-workgroup-symbolic";
    }
    
    public override string get_name () {
        return _("Federated Timeline");
    }
    
    protected Soup.Message get_stream () {
        var url = "%s/api/v1/streaming/?stream=public&access_token=%s".printf (accounts.formal.instance, accounts.formal.token);
        return new Soup.Message("GET", url);
    }

}
