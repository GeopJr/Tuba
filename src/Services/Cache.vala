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
        public int references { get; construct set; }

        public Item (Pixbuf d, int r) {
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
        if (item.references <= 0) {
            // message (@"[X] $(r.key)");
            items.remove (r.key);
            items_in_progress.remove (r.key);
        }
        // else {
        //     message (@"[-] $(r.key) - $(item.references)");
        // }
    }

    public void load (string? url, owned CachedResultCallback cb) {
        if (url == null)
            return;

        var key = url;
        if (items.contains (key)) {
            var item = items.@get (key);
            item.references++;
            // message (@"[+] $key - $(item.references)");
            cb (Reference () {
                data = item.data,
                key = key,
                loading = false
            });
            return;
        }

        //var item = items.@get (key);

        var msg = items_in_progress.@get (key);
        if (msg == null) {
            msg = new Soup.Message ("GET", url);
            ulong id = 0;
            id = msg.finished.connect (() => {
                Pixbuf? pixbuf = null;

                try {
                    var code = message.status_code;
					if (code != Soup.Status.OK) {
					    var msg = network.describe_error (code);
					    throw new Oopsie.INSTANCE (@"Server returned $msg");
					}

                    var data = message.response_body.flatten ().data;
                    var stream = new MemoryInputStream.from_data (data);
                    pixbuf = new Pixbuf.from_stream (stream);
                    stream.close ();
                }
                catch (Error e) {
                    warning (@"\"$url\" -> Pixbuf: FAIL ($(e.message))");
                    pixbuf = Desktop.icon_to_pixbuf ("image-x-generic-symbolic");
                }

                // message (@"[*] $key");
                items[key] = new Item (pixbuf, 1);
                items_in_progress.remove (key);

                cb (Reference () {
                    data = items[key].data,
                    key = key,
                    loading = false
                });

                msg.disconnect (id);
            });

            network.queue (msg, (sess, mess) => {
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

            items_in_progress.insert (key, msg);
        }
        else {
            //message ("[/]: %s", key);
            ulong id = 0;
            id = msg.finished.connect_after (() => {
                var it = items.@get (key);
                cb (Reference () {
                    data = it.data,
                    key = key,
                    loading = false
                });
                it.references++;
                msg.disconnect (id);
            });
        }
    }

    public void clear () {
        // message ("[ CLEARED ALL ]");
        items.remove_all ();
        items_in_progress.remove_all ();
    }
}
