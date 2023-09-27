public class Tuba.API.Funkwhale : Entity {
	public Gee.ArrayList<API.FunkwhaleTrack>? uploads { get; set; default=null; }

	public void get_track (string special_host, out string res_url, out bool failed) {
		res_url = "";
		failed = true;
		if (this.uploads != null && this.uploads.size > 0) {
			var funkwhale_track = this.uploads.get (0);

			if (funkwhale_track.listen_url != "") {
				failed = false;
				res_url = @"https://$(special_host)$(funkwhale_track.listen_url)";
			}
		}
	}

	public override Type deserialize_array_type (string prop) {
		if (prop == "uploads") {
			return typeof (API.FunkwhaleTrack);
		}

		return base.deserialize_array_type (prop);
	}

	public static Funkwhale from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Funkwhale), node) as API.Funkwhale;
	}
}
