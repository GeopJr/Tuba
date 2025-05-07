// https://fedilinks.org/spec/en/6-The-web-ap-URI
public class Tuba.Utils.WebApHandler {
	public static string from_uri (Uri uri) {
		return Uri.join (
			uri.get_flags (),
			"https",
			null,
			uri.get_host (),
			uri.get_port (),
			uri.get_path (),
			uri.get_query (),
			uri.get_fragment ()
		);
	}
}
