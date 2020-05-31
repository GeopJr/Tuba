public class Build {

	public const string NAME = "Tootle";
	public const string WEBSITE = "https://github.com/bleakgrey/tootle";
	public const string DOMAIN = "com.github.bleakgrey.tootle";
	public const string RESOURCES = "/com/github/bleakgrey/tootle/";
	public const string VERSION = "1.0.0";

    public static void print_info () {
    	var os_name = get_os_info ("NAME");
    	var os_ver = get_os_info ("VERSION");
        message (@"$(Build.NAME) $(Build.VERSION)");
        message (@"Running on: $os_name $os_ver");
        message (@"Build type: FROM_SOURCE");
    }

	static string get_os_info (string key) {
		var result = GLib.Environment.get_os_info (key);
		return result == null ? "Unknown" : result;
	}

}
