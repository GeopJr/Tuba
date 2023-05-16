public class Tuba.API.PreviewCard : Entity {
	public enum CardSpecialType {
		BASIC,
		PEERTUBE,
		FUNKWHALE,
		BOOKWYRM;

		public string to_string () {
			switch (this) {
				case PEERTUBE:
					return "PeerTube";
				case FUNKWHALE:
					return "Funkwhale";
				case BOOKWYRM:
					return "BookWyrm";
				default:
					return "";
			}
		}
	}

	public string url { get; set; }
	public string title { get; set; default=""; }
	public string description { get; set; default=""; }
	public string kind { get; set; default="link"; }
	public string author_name { get; set; default=""; }
	public string author_url { get; set; default=""; }
	public string provider_name { get; set; default=""; }
	public string provider_url { get; set; default=""; }
	public string? image { get; set; default=null; }
	public CardSpecialType card_special_type {
		get {
			if (is_peertube) {
				return CardSpecialType.PEERTUBE;
			} else if (is_funkwhale) {
				return CardSpecialType.FUNKWHALE;
			} else if (is_bookwyrm) {
				return CardSpecialType.BOOKWYRM;
			}

			return CardSpecialType.BASIC;
		}
	}

    public bool is_peertube {
        get {
			// Disable PeerTube support for now
			// see #253
			#if false
				bool url_pt = url.last_index_of ("/videos/watch/") > -1;

				return kind == "video" && provider_name == "PeerTube" && url_pt;
			#else
				return false;
			#endif
		}
    }

	public bool is_funkwhale {
        get {
			bool provider_fw = provider_name.last_index_of ("- Funkwhale") > 0;
			bool url_fw = url.last_index_of ("/library/tracks/") > -1;

			return kind == "video" && provider_fw && url_fw;
		}
    }

	public bool is_bookwyrm {
        get {
			bool title_bw = title.last_index_of ("- BookWyrm") > 0;
			bool url_bw = url.last_index_of ("/book/") > -1;

			return kind == "link" && title_bw && url_bw;
		}
    }
}
