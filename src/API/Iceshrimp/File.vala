public class Tuba.API.Iceshrimp.File : Entity {
	public string id { get; set; }
	public string url { get; set; }
	public string thumbnailUrl { get; set; } // vala-lint=naming-convention
	public string filename { get; set; }
	public string contentType { get; set; } // vala-lint=naming-convention
	public bool sensitive { get; set; }
	public string? description { get; set; }
	public bool isAvatar { get; set; } // vala-lint=naming-convention
	public bool isBanner { get; set; } // vala-lint=naming-convention
}
