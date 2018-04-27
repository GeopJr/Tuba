using Gdk;
using GLib;

public class Tootle.CacheManager : GLib.Object{
    
    private static string path_images;

    construct{
        path_images = GLib.Environment.get_user_special_dir (UserDirectory.DOWNLOAD);
    }

    public CacheManager(){
        Object ();
    }
    
    //TODO: actually cache images
    public void load_avatar (string url, Granite.Widgets.Avatar avatar, int size){
        var msg = new Soup.Message("GET", url);
        msg.finished.connect(()=>{
                uint8[] buf = msg.response_body.data;
                var loader = new PixbufLoader();
                loader.set_size (size, size);
                loader.write(buf);
                loader.close();
                var pixbuf = loader.get_pixbuf ();
                
                avatar.pixbuf = pixbuf;
        });
        Tootle.network.queue(msg, (sess, mess) => {});
    }

}
