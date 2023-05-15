public class Tuba.API.PeerTube : Entity {
	public string url { get; set; }
	public Gee.ArrayList<API.PeerTubeStreamingPlaylist>? streamingPlaylists { get; set; default=null; }
	public Gee.ArrayList<API.PeerTubeFile>? files { get; set; default=null; }

	public static PeerTube from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.PeerTube), node) as API.PeerTube;
	}
}
