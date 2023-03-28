public class Tuba.API.Mastodon.Configuration.MediaAttachments : Entity {
	public Gee.ArrayList<string> supported_mime_types { get; set; }
	public int64 image_size_limit { get; set; }
	public int64 image_matrix_limit { get; set; }
	public int64 video_size_limit { get; set; }
	public int64 video_frame_rate_limit { get; set; }
	public int64 video_matrix_limit { get; set; }
}
