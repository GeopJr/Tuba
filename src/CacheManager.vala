using Gdk;
using GLib;

public class Tootle.CacheManager : GLib.Object{
    
    private static string path_images;

    construct{
        path_images = GLib.Environment.get_user_special_dir (UserDirectory.DOWNLOAD);
    }

    //TODO: actually cache images
    public CacheManager(){
        Object ();
    }
    
    public void load_avatar (string url, Granite.Widgets.Avatar avatar, int size){
        var msg = new Soup.Message("GET", url);
        msg.finished.connect(() => {
                var loader = new PixbufLoader();
                loader.set_size (size, size);
                loader.write(msg.response_body.data);
                loader.close();
                avatar.pixbuf = loader.get_pixbuf ();
        });
        Tootle.network.queue(msg, (sess, mess) => {});
    }
    
    public void load_image (string url, Gtk.Image image){
        var msg = new Soup.Message("GET", url);
        msg.finished.connect(() => {
                var loader = new PixbufLoader();
                loader.write(msg.response_body.data);
                loader.close();
                image.set_from_pixbuf (loader.get_pixbuf ());
        });
        Tootle.network.queue(msg, (sess, mess) => {});
    }

}
