public class Tuba.API.PeerTubeStreamingPlaylist : Entity {
	public Gee.ArrayList<API.PeerTubeFile>? files { get; set; default=null; }

	public override Type deserialize_array_type (string prop) {
		if (prop == "files") {
			return typeof (API.PeerTubeFile);
		}

		return base.deserialize_array_type (prop);
	}
}
