public class Tuba.Utils.ShareHandler {
	public struct ShareResult {
		public string text;
		public string? cw;
	}

	public static ShareResult? from_uri (Uri uri) {
		string? query = uri.get_query ();
		if (query == null || query == "") return null;

		try {
			var compose_params = Uri.parse_params (query);
			if (!compose_params.contains ("text")) return null;

			string text = compose_params.get ("text");
			string? cw = null;
			if (compose_params.contains ("cw")) cw = compose_params.get ("cw");

			return { text, cw };
		} catch (GLib.UriError e) {
			warning (e.message);
			return null;
		}
	}
}
