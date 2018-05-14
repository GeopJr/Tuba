using Gtk;

public class Tootle.RichLabel : Gtk.Label {

    public weak Mention[]? mentions;

    public RichLabel (string text, bool override_links = true) {
        label = text;
        set_use_markup (true);
        
        if (override_links)
            activate_link.connect (open_link);
    }
    
    public void wrap_words () {
        halign = Gtk.Align.START;
        single_line_mode = false;
        set_line_wrap (true);
        wrap_mode = Pango.WrapMode.WORD_CHAR;
        justify = Gtk.Justification.LEFT;
        xalign = 0;
    }
    
    public bool open_link (string url){
        if (mentions != null){
            foreach (Mention mention in mentions) {
                if (url == mention.url){
                    AccountView.open_from_id (mention.id);
                    return true;
                }
            }
        }
        
        if ("/tags/" in url){
            var encoded = url.split("/tags/")[1];
            var hashtag = Soup.URI.decode (encoded);
            var feed = new HomeView ("tag/" + hashtag);
            Tootle.window.open_view (feed);
            return true;
        }
        
        if ("/@" in url){
            var profile = url.split("/@")[1];
            AccountView.open_from_name (profile);
            return true;
        }
    
        Tootle.Utils.open_url (url);
        return true;
    }

}
