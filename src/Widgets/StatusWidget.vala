using Gtk;
using Granite;

public class Tootle.StatusWidget : Gtk.Grid {
    
    public Granite.Widgets.Avatar avatar;
    Gtk.Label user;
    Gtk.Label content;
    
    Gtk.Box counters;
    Gtk.Label reblogs;
    Gtk.Label favorites;

    construct {
        margin = 6;
        avatar = new Granite.Widgets.Avatar.with_default_icon (32);
        avatar.valign = Gtk.Align.START;
        avatar.margin_end = 6;
        user = new Gtk.Label ("Anonymous");
        user.hexpand = true;
        user.halign = Gtk.Align.START;
        user.use_markup = true;
        content = new Gtk.Label ("Error parsing text :c");
        content.halign = Gtk.Align.START;
        content.use_markup = true;
        content.single_line_mode = false;
        content.set_line_wrap (true);
        //content.selectable = true; //TODO: toot page
        content.justify = Gtk.Justification.LEFT;
        content.margin_end = 6;
        content.xalign = 0;
        
        reblogs = new Gtk.Label ("0");
        favorites = new Gtk.Label ("0");
        counters = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        counters.margin_top = 6;
        counters.margin_bottom = 12;
        counters.add(new Gtk.Image.from_icon_name ("media-playlist-repeat-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
        counters.add(reblogs);
        counters.add(new Gtk.Image.from_icon_name ("user-bookmarks-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
        counters.add(favorites);
        counters.show_all ();
        
        attach(avatar, 0, 0, 1, 3);
        attach(user, 1, 1, 1, 1);
        attach(content, 1, 2, 1, 1);
        attach(counters, 1, 3, 1, 1);
        show_all();
    }

    public StatusWidget () {
        get_style_context ().add_class ("status");
    }
    
    public void rebind (Status status){
        user.label = "<b>"+status.acct+"</b>";
        content.label = status.content;
        
        reblogs.label = status.reblogs_count.to_string ();
        favorites.label = status.favourites_count.to_string ();
        
        CacheManager.instance.load_image (status.avatar, this.avatar);
    }

}
