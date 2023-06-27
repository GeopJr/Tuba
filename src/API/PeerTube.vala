public class Tuba.API.PeerTube : Entity {
	public string url { get; set; }
	public Gee.ArrayList<API.PeerTubeStreamingPlaylist>? streamingPlaylists { get; set; default=null; }
	public Gee.ArrayList<API.PeerTubeFile>? files { get; set; default=null; }

	// Anything higher is usually very laggy
	const int64[] IDEAL_PEERTUBE_RESOLUTION = { 720, 480, 360 };
	public void get_video (string t_url, out string res_url, out bool failed) {
		failed = true;
		var t_res = "";
		if (this.url == t_url) {
			var peertube_file_list = this.files;
			if ((peertube_file_list == null || peertube_file_list.size == 0) && this.streamingPlaylists != null && this.streamingPlaylists.size > 0) {
				peertube_file_list = this.streamingPlaylists.get(0).files;
			}

			if (peertube_file_list != null && peertube_file_list.size > 0) {
				peertube_file_list.foreach (file => {
					if (file.fileDownloadUrl == "" || file.resolution == null) return true;
					t_res = file.fileDownloadUrl;

					if (file.resolution.id in IDEAL_PEERTUBE_RESOLUTION) return false;
					return true;
				});

				if (t_res != "") failed = false;
			}
		}
		res_url = t_res;
	}

	public static PeerTube from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.PeerTube), node) as API.PeerTube;
	}
}
