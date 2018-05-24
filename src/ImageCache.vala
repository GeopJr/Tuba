using Soup;
using GLib;
using Gdk;
using Json;

private struct CachedImage {
    public string uri;
    public int size;
    
    public CachedImage(string uri, int size) { this.uri=uri; this.size=size; }
    
    public static uint hash(CachedImage? c) {
        assert(c != null);
        assert(c.uri != null);
        return GLib.int64_hash(c.size) ^ c.uri.hash();
    }
    
    public static bool equal(CachedImage? a, CachedImage? b) {
        if (a == null || b == null) { return false; }
        return a.size == b.size && a.uri == b.uri;
    }
}

public delegate void PixbufCallback (Gdk.Pixbuf pb);

public class Tootle.ImageCache : GLib.Object {
    private GLib.HashTable<CachedImage?, Soup.Message> in_progress;
    private GLib.HashTable<CachedImage?, Gdk.Pixbuf> pixbufs;
    private uint total_size_est;
    private uint size_limit;
    
    construct {
        pixbufs = new GLib.HashTable<CachedImage?, Gdk.Pixbuf>(CachedImage.hash, CachedImage.equal);
        in_progress = new GLib.HashTable<CachedImage?, Soup.Message>(CachedImage.hash, CachedImage.equal);
        total_size_est = 0;
        Tootle.settings.changed.connect (on_settings_changed);
        on_settings_changed ();
    }
    
    public ImageCache() {
        GLib.Object();
    }
    
    // adopts cache size limit from settings
    private void on_settings_changed () {
        // assume 32BPP (divide bytes by 4 to get # pixels) and raw, overhead-free storage
        // cache_size setting is number of megabytes
        size_limit = (1024 * 1024 * Tootle.settings.cache_size / 4);
        enforce_size_limit ();
    }
    
    // remove all cached images
    public void remove_all () {
        GLib.debug("image cache cleared");
        pixbufs.remove_all ();
        total_size_est = 0;
    }
    
    // remove any entry for the given uri and size from the cache
    public void remove_one (string uri, int size) {
        GLib.debug("image cache removing %s", uri);
        CachedImage ci = CachedImage (uri, size);
        bool removed = pixbufs.remove(ci);
        if (removed) {
            assert (total_size_est >= size * size);
            total_size_est -= size * size;
            GLib.debug("image cache removed %s; size est. is %zd", uri, total_size_est);
        }
    }
    
    // delete the pixbuf with the smallest reference count from the cache
    private void remove_least_used () {
        GLib.debug("image cache removing least-used");
        // for now, dummy implementation: just remove the first pixbuf
        var keys = pixbufs.get_keys();
        if (keys.first() != null) {
            var ci = keys.first().data;
            remove_one(ci.uri, ci.size);
        }
    }
    
    private void enforce_size_limit () {
        GLib.debug("image cache enforcing size limit (%zd/%zd)", total_size_est, size_limit);
        while (total_size_est > size_limit && pixbufs.size() > 0) {
            remove_least_used ();
        }
        assert (total_size_est <= size_limit);
    }

    private void store_pixbuf (CachedImage ci, Gdk.Pixbuf pixbuf) {
        GLib.debug("image cache inserting %s@%d", ci.uri, ci.size);
        assert (!pixbufs.contains (ci));
        pixbufs.insert (ci, pixbuf);
        in_progress.remove (ci);
        total_size_est += ci.size * ci.size;
        enforce_size_limit ();
    }
    
    public async void get_image (string uri, int size, owned PixbufCallback? cb = null) {
        CachedImage ci = CachedImage (uri, size);
        Gdk.Pixbuf? pb = pixbufs.get(ci);
        if (pb != null) {
            cb (pb);
            return;
        }
        GLib.debug("image cache miss for %s@%d", uri, size);
        
        Soup.Message? msg = in_progress.get(ci);
        if (msg == null) {
            msg = new Soup.Message("GET", uri);
            msg.finished.connect(() => {
                GLib.debug("image cache about to insert %s@%d", uri, size);
                var data = msg.response_body.data;
                var stream = new MemoryInputStream.from_data (data);
                var pixbuf = new Gdk.Pixbuf.from_stream_at_scale (stream, size, size, true);
                store_pixbuf(ci, pixbuf);
                cb(pixbuf);
            });
            in_progress[ci] = msg;
            Tootle.network.queue (msg);
        } else {
            GLib.debug("found in-progress request for %s@%d", uri, size);
            msg.finished.connect_after(() => {
                GLib.debug("in-progress request finished for %s@%d", uri, size);
                cb(pixbufs[ci]);
            });
        }
    }
    
    public void load_avatar (string uri, Granite.Widgets.Avatar avatar, int size = 32) {
        get_image.begin(uri, size, (pixbuf) => avatar.pixbuf = pixbuf);
    }
    
    public void load_image (string uri, Gtk.Image image) {
        load_scaled_image(uri, image, -1);
    }
    
    public void load_scaled_image (string uri, Gtk.Image image, int size = 64) {
        get_image.begin(uri, size, image.set_from_pixbuf);
    }
}
