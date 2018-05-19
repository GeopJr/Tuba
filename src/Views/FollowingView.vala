using Gtk;

public class Tootle.FollowingView : FollowersView {

    public FollowingView (ref Account account) {
        base (ref account);
        
    }
    
    public override string get_url (){
        if (page_next != null)
            return page_next;
        
        var url = "%s/api/v1/accounts/%s/following".printf (Tootle.settings.instance_url, this.timeline);
        return url;
    }

}
