public class Tuba.Utils.Exif {
	const string[] ALT_KEYS = {
		"Xmp.iptc.AltTextAccessibility",
		"Xmp.dc.description",
		"Iptc.Application2.Caption",
		"Exif.Image.ImageDescription",
		"Exif.Photo.UserComment",
		"Xmp.acdsee.notes",
		"Exif.Image.XPComment"
	};

	public static string? extract_alt_text (string path) {
		string? result = null;

		try {
			GExiv2.Metadata metadata = new GExiv2.Metadata ();

			string meta_path = path;
			if (meta_path.has_prefix ("file://")) {
				meta_path = meta_path.substring (7);
			}
			metadata.open_path (meta_path);

			result = extract_alt_text_from_metadata (metadata);
		} catch (Error e) {
			critical (@"Error while extracting alt text: $(e.message)");
		}

		return result;
	}

	public static string? extract_alt_text_from_metadata (GExiv2.Metadata metadata) throws Error {
		string? result = null;

		foreach (string tag in ALT_KEYS) {
			if (metadata.try_has_tag (tag)) {
				string? alt = metadata.try_get_tag_interpreted_string (tag);
				if (alt != null && alt.length > 0) {
					result = alt;

					if (result.has_prefix ("lang=\"x-default\" ")) {
						result = result.substring (17);
					} else if (result.has_prefix ("lang=\"en\" ")) {
						result = result.substring (10);
					}
					break;
				}
			}
		}

		return result;
	}
}
