public class Tuba.API.PeerTubeFile : Entity {
	public API.PeerTubeResolution? resolution { get; set; default=null; }
	public string? fileDownloadUrl { get; set; default=""; } // vala-lint=naming-convention
}
