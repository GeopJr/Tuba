public class Tootle.FollowingView : FollowersView {

    public FollowingView (Account account) {
        base (account);
        
    }
    
    public override string get_url (){
        if (page_next != null)
            return page_next;
        
        var url = "%s/api/v1/accounts/%s/following".printf (accounts.formal.instance, this.timeline);
        return url;
    }

}
