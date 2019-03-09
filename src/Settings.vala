public class Tootle.Settings : Granite.Services.Settings {

    public int current_account { get; set; }
    public bool notifications { get; set; }
    public bool always_online { get; set; }
    public bool cache { get; set; }
    public int cache_size { get; set; }
    public int char_limit { get; set; }
    public bool live_updates { get; set; }
    public bool live_updates_public { get; set; }
    public bool dark_theme { get; set; }
    public string watched_users { get; set; }
    public string watched_hashtags { get; set; }

    public int window_x { get; set; }
    public int window_y { get; set; }
    public int window_w { get; set; }
    public int window_h { get; set; }

    public Settings () {
        base ("com.github.bleakgrey.tootle");
    }

}
