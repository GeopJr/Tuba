using Gee;
using Gdk;

public class Tootle.Cache : GLib.Object {

    protected HashTable<string, Item> items { get; set; }
    protected HashTable<string, Soup.Message> items_in_progress { get; set; }
    protected uint size {
        get {
            return items.size ();
        }
    }

    construct {
        items = new HashTable<string, Item> (GLib.str_hash, GLib.str_equal);
        items_in_progress = new HashTable<string, Soup.Message> (GLib.str_hash, GLib.str_equal);
    }

    public delegate void CachedResultCallback (Reference? result);

    public struct Reference {
        public string key;
        public weak Pixbuf? data;
        public bool loading;
    }

    protected class Item : GLib.Object {
        public Pixbuf data { get; construct set; }
        public int64 references { get; construct set; }

        public Item (Pixbuf d, int64 r) {
            Object (data: d, references: r);
        }
    }

    public void unload (Reference? r) {
        if (r == null)
            return;

        if (r.data == null)
            return;

        var item = items[r.key];
        if (item == null)
            return;

        item.references--;
        //info (@"DEREF $(r.key) $(item.references)");
        if (item.references <= 0) {
            //info ("REMOVE %s", r.key);
            items.remove (r.key);
            items_in_progress.remove (r.key);
        }
    }

    public void load (string? url, owned CachedResultCallback cb) {
        if (url == null)
            return;

        var key = url;
        if (items.contains (key)) {
            //info (@"LOAD $key");
            var item = items.@get (key);
            item.references++;
            cb (Reference () {
                data = item.data,
                key = key,
                loading = false
            });
            return;
        }

        var item = items.@get (key);

        var message = items_in_progress.@get (key);
        if (message == null) {
            message = new Soup.Message ("GET", url);
            ulong id = 0;
            id = message.finished.connect (() => {
                Pixbuf? pixbuf = null;

                var data = message.response_body.flatten ().data;
                var stream = new MemoryInputStream.from_data (data);
                pixbuf = new Pixbuf.from_stream (stream);
                stream.close ();

                //info (@"< STORE $key");
                items[key] = new Item (pixbuf, 1);
                items_in_progress.remove (key);

                cb (Reference () {
                    data = items[key].data,
                    key = key,
                    loading = false
                });

                message.disconnect (id);
            });

            network.queue (message, (sess, msg) => {
                // no one cares
            },
            (code, reason) => {
                cb (null);
            });

            cb (Reference () {
                data = null,
                key = key,
                loading = true
            });

            items_in_progress.insert (key, message);
        }
        else {
            //info ("AWAIT: %s", key);
            ulong id = 0;
            id = message.finished.connect_after (() => {
                var it = items.@get (key);
                cb (Reference () {
                    data = it.data,
                    key = key,
                    loading = false
                });
                it.references++;
                message.disconnect (id);
            });
        }
    }

    public void clear () {
        info ("PURGE");
        items.remove_all ();
        items_in_progress.remove_all ();
    }
}
