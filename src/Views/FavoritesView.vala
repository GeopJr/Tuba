using Gtk;

public class Tootle.FavoritesView : TimelineView {

    public FavoritesView () {
        base ("favorites");
    }
    
    public override string get_url (){
        if (page_next != null)
            return page_next;
        
        var url = "%s/api/v1/favourites/?limit=%i".printf (Tootle.accounts.formal.instance, this.limit);
        return url;
    }

}
