public class Tootle.LocalView : TimelineView {

    public LocalView () {
        base ("public");
    }

    public override string get_icon () {
        return Desktop.fallback_icon ("system-users-symbolic", "document-open-recent-symbolic");
    }

    public override string get_name () {
        return _("Local Timeline");
    }

    public override string get_url (){
        var url = base.get_url ();
        url += "&local=true";
        return url;
    }

    protected override bool is_public () {
        return true;
    }

    public override Soup.Message? get_stream () {
        var url = "%s/api/v1/streaming/?stream=public:local&access_token=%s".printf (accounts.formal.instance, accounts.formal.token);
        return new Soup.Message("GET", url);
    }

}
