public class Tootle.HomeView : TimelineView {

    public HomeView () {
        base ("home");
        notificator = new Notificator (accounts.formal.get_stream ());
        notificator.status_added.connect ((ref status) => {
            if (settings.live_updates)
                on_status_added (ref status);
        });
    }
    
    public override string get_icon () {
        return "user-home-symbolic";
    }
    
    public override string get_name () {
        return _("Home");
    }

}
