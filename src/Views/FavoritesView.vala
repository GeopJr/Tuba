using Gtk;

public class Tootle.FavoritesView : Tootle.HomeView {

    public FavoritesView () {
        base ("favorites");
        request ();
    }
    
    public override string get_url (){
        var url = "%s/api/v1/favourites?limit=25".printf (Tootle.settings.instance_url);
        
        if (max_id > 0)
            url += "&max_id=" + max_id.to_string ();
        
        return url;
    }

}
