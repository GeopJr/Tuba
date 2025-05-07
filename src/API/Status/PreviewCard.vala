public class Tuba.API.PreviewCard : Entity, Widgetizable {
	public enum CardSpecialType {
		BASIC,
		PEERTUBE,
		FUNKWHALE,
		BOOKWYRM,
		CLAPPER;

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

		public string to_dialog_title () {
			switch (this) {
				case PEERTUBE:
					// translators: the variable is an external service like "PeerTube"
					return _("You are about to open a %s video").printf (this.to_string ());
				case FUNKWHALE:
					// translators: the variable is an external service like "Funkwhale",
					//				track as in song
					return _("You are about to open a %s track").printf (this.to_string ());
				case BOOKWYRM:
					// translators: the variable is an external service like "BookWyrm"
					return _("You are about to open a %s book").printf (this.to_string ());
				case CLAPPER:
					return _("You are about to open a video");
				default:
					// translators: the variable is the app name (Tuba)
					return _("You are about to leave %s").printf (Build.NAME);
			}
		}

		public string to_dialog_body (string t_url) {
			var dlg_url = t_url;
			if (dlg_url.length > 64) {
				dlg_url = t_url.substring (0, 62) + "…";
			}

			switch (this) {
				case BASIC:
					// translators: the variable is a url
					return _("If you proceed, \"%s\" will open in your browser.").printf (dlg_url);
				default:
					// translators: the first variable is the app name (Tuba),
					//				the second one is a url
					return _("If you proceed, %s will connect to \"%s\".").printf (Build.NAME, dlg_url);
			}
		}
	}

	public class AuthorEntity : Entity {
		public string? name { get; set; }
		public string? url { get; set; }
		public API.Account? account { get; set; }
	}

	public string url { get; set; }
	public string title { get; set; default=""; }
	public string description { get; set; default=""; }
	public string kind { get; set; default="link"; }
	public string author_name { get; set; default=""; }
	public string author_url { get; set; default=""; }
	public Gee.ArrayList<AuthorEntity>? authors { get; set; default=null; }
	public string provider_name { get; set; default=""; }
	public string provider_url { get; set; default=""; }
	public string? image { get; set; default=null; }
	public string? blurhash { get; set; default=null; }
	public Gee.ArrayList<API.TagHistory>? history { get; set; default = null; }

	private GLib.Uri? _tuba_uri = null;
	public GLib.Uri? tuba_uri {
		get {
			if (_tuba_uri == null) {
				try {
					_tuba_uri = GLib.Uri.parse (this.url, GLib.UriFlags.NONE);
				} catch {}
			}

			return _tuba_uri;
		}
	}

	private CardSpecialType? _special_card = null;
	public CardSpecialType special_card {
		get {
			if (_special_card == null) {
				if (is_peertube) {
					#if CLAPPER
						if (Clapper.enhancer_check (typeof (Clapper.Extractable), "peertube", null, null)) {
							_special_card = CardSpecialType.PEERTUBE;
						} else {
							_special_card = CardSpecialType.BASIC;
						}
					#else
						_special_card = CardSpecialType.PEERTUBE;
					#endif
				} else if (is_funkwhale) {
					_special_card = CardSpecialType.FUNKWHALE;
				} else if (is_bookwyrm) {
					_special_card = CardSpecialType.BOOKWYRM;
				} else {
					_special_card = CardSpecialType.BASIC;
					#if CLAPPER
						// TODO: maybe limit to https only
						if (Clapper.enhancer_check (typeof (Clapper.Extractable), this.tuba_uri.get_scheme (), this.tuba_uri.get_host (), null))
							_special_card = CardSpecialType.CLAPPER;
					#endif
				}
			}

			return _special_card;
		}
	}

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "history":
				return typeof (API.TagHistory);
			case "authors":
				return typeof (AuthorEntity);
		}

		return base.deserialize_array_type (prop);
	}

	private bool is_peertube {
		get {
			#if CLAPPER
				return kind == "video" && provider_name == "PeerTube";
				// #253
			#else
				return false;
			#endif
		}
	}

	private bool is_funkwhale {
		get {
			bool provider_fw = provider_name.last_index_of ("- Funkwhale") > 0;
			bool url_fw = url.last_index_of ("/library/tracks/") > -1;

			return kind == "video" && provider_fw && url_fw;
		}
	}

	private bool is_bookwyrm {
		get {
			return kind == "link" && bookwyrm_regex.match (url);
		}
	}

	public override Gtk.Widget to_widget () {
		if (this.kind == "link" && this.history != null) return new Widgets.PreviewCardExplore (this);

		return new Widgets.PreviewCard (this);
	}

	public void open_special_card () {
		if (this.tuba_uri == null) {
			open_url (this.url);
			return;
		}

		string api_url = "";
		string host = this.tuba_uri.get_host ();
		switch (this.special_card) {
			case FUNKWHALE:
				api_url = @"https://$(host)/api/v1/tracks/$(Path.get_basename (this.tuba_uri.get_path ()))";
				break;
			case BOOKWYRM:
				var bookwyrm_path = this.tuba_uri.get_path ();
				var b_id_start = bookwyrm_path.index_of_char ('/', 1);
				var b_id_end = bookwyrm_path.index_of_char ('/', b_id_start + 1) - 1;
				if (b_id_end <= -1) b_id_end = bookwyrm_path.length - 1;
				var bookwyrm_id = bookwyrm_path.substring (b_id_start + 1, b_id_end - b_id_start);

				api_url = @"https://$(host)/book/$(bookwyrm_id).json";
				break;
			#if CLAPPER
				case API.PreviewCard.CardSpecialType.CLAPPER:
				case API.PreviewCard.CardSpecialType.PEERTUBE:
					string fin_url = this.url;
					if (this.special_card == API.PreviewCard.CardSpecialType.PEERTUBE) {
						fin_url = GLib.Uri.build (
							this.tuba_uri.get_flags (),
							"peertube",
							this.tuba_uri.get_userinfo (),
							host,
							this.tuba_uri.get_port (),
							this.tuba_uri.get_path (),
							this.tuba_uri.get_query (),
							this.tuba_uri.get_fragment ()
						).to_string ();
					}

					app.main_window.show_media_viewer (fin_url, Tuba.Attachment.MediaType.VIDEO, null, null, false, null, fin_url, null, true);
					return;
			#endif
			default:
				open_url (this.url);
				return;
		}

		new Request.GET (api_url)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);

				switch (this.special_card) {
					case API.PreviewCard.CardSpecialType.FUNKWHALE:
						var funkwhale_obj = API.Funkwhale.from (node);
						string res_url;

						if (funkwhale_obj.get_track (host, out res_url)) {
							app.main_window.show_media_viewer (res_url, Tuba.Attachment.MediaType.AUDIO, null, null, false, null, this.url, null, true);
						}
						break;
					case API.PreviewCard.CardSpecialType.BOOKWYRM:
						API.BookWyrm bookwyrm_obj = API.BookWyrm.from (node);

						if (bookwyrm_obj.title != null && bookwyrm_obj.title != "") {
							app.main_window.show_book (bookwyrm_obj, this.url);
						}
						break;
					default:
						open_url (this.url);
						break;
				}
			})
			.on_error (() => {
				open_url (this.url);
			})
			.exec ();
	}

	private void open_url (string url) {
		#if WEBKIT
			if (settings.use_in_app_browser_if_available && Views.Browser.can_handle_url (url)) {
				(new Views.Browser.with_url (url)).present (app.main_window);
				return;
			}
		#endif

		Host.open_url.begin (url);
	}
}
