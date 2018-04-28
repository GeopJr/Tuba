using Gtk;

public class Tootle.RichLabel : Gtk.Label {

    public weak Mention[]? mentions;

    public RichLabel (string text, bool override_links = true) {
        label = text;
        set_use_markup (true);
        
        if (override_links)
            activate_link.connect (open_link);
    }
    
    public bool open_link (string url){
        if (mentions != null){
            foreach (Mention mention in mentions){
                if (url == mention.url){
                    AccountView.open_from_id (mention.id);
                    return true;
                }
            }
        }
        
        if ("/tags/" in url){
            var hashtag = url.split("/tags/")[1];
            //TODO: search hashtags
            return true;
        }
        
        if ("/@" in url){
            var profile = url.split("/@")[1];
            //TODO: search profiles
            return true;
        }
    
        Gtk.show_uri (null, url, Gdk.CURRENT_TIME);
        return true;
    }

}
