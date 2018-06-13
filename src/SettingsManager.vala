public class Tootle.SettingsManager : Granite.Services.Settings {
    
    public int current_account { get; set; }
    public bool notifications { get; set; }
    public bool always_online { get; set; }
    public bool cache { get; set; }
    public int cache_size { get; set; }
    public int char_limit { get; set; }
    public bool live_updates { get; set; }
    public bool live_updates_public { get; set; }
    public bool dark_theme { get; set; }

    public SettingsManager () {
        base ("com.github.bleakgrey.tootle");
    }

}
