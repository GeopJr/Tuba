public class Tuba.API.Iceshrimp.Folder : Entity {
	public string? id { get; set; default=null; }
	public string name { get; set; default=_("Folder"); }
	public string? parentId { get; set; default=null; } // vala-lint=naming-convention
	public Gee.ArrayList<Iceshrimp.File>? files { get; set; default = null; }
	public Gee.ArrayList<Folder>? folders { get; set; default = null; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "files":
				return typeof (Iceshrimp.File);
			case "folders":
				return typeof (Folder);
		}

		return base.deserialize_array_type (prop);
	}

	public static Folder from (Json.Node node) throws Error {
		return Entity.from_json (typeof (Folder), node) as Folder;
	}
}
