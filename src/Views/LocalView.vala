public class Tootle.LocalView : TimelineView {

    public LocalView () {
        base ("public");
        notificator = new Notificator (get_stream ());
        notificator.status_added.connect ((ref status) => {
            if (settings.live_updates_public)
                on_status_added (ref status);
        });
    }
    
    public override string get_icon () {
        return "document-open-recent-symbolic";
    }
    
    public override string get_name () {
        return _("Local Timeline");
    }
    
    public override string get_url (){
        var url = base.get_url ();
        url += "&local=true";
        return url;
    }
    
    protected Soup.Message get_stream () {
        var url = "%s/api/v1/streaming/?stream=public:local&access_token=%s".printf (accounts.formal.instance, accounts.formal.token);
        return new Soup.Message("GET", url);
    }

}
