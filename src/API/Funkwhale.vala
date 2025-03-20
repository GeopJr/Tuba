public class Tuba.API.Funkwhale : Entity {
	public Gee.ArrayList<API.FunkwhaleTrack>? uploads { get; set; default=null; }

	public bool get_track (string special_host, out string res_url) {
		res_url = "";
		if (this.uploads != null && this.uploads.size > 0) {
			var funkwhale_track = this.uploads.get (0);

			if (funkwhale_track.listen_url != "") {
				res_url = @"https://$(special_host)$(funkwhale_track.listen_url)";
				return true;
			}
		}

		return false;
	}

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "uploads":
				return typeof (API.FunkwhaleTrack);
		}

		return base.deserialize_array_type (prop);
	}

	public static Funkwhale from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Funkwhale), node) as API.Funkwhale;
	}
}
