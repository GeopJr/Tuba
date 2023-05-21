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

		public string to_dialog_title () {
			switch (this) {
				case PEERTUBE:
					// translators: the variable is an external service like "PeerTube"
					return _("You are about to open a %s video").printf (@"$this");
				case FUNKWHALE:
					// translators: the variable is an external service like "Funkwhale",
					//				track as in song
					return _("You are about to open a %s track").printf (@"$this");
				case BOOKWYRM:
					// translators: the variable is an external service like "BookWyrm"
					return _("You are about to open a %s book").printf (@"$this");
				default:
					// translators: the variable is the app name (Tuba)
					return _("You are about to leave %s").printf (Build.NAME);
			}
		}

		public string to_dialog_body (string t_url) {
			var dlg_url = t_url;
			if (dlg_url.length > 64) {
				dlg_url = t_url.substring(0, 62) + "…";
			}

			switch (this) {
				case BASIC:
					// translators: the variable is a url
					return _("If you proceed, \"%s\" will open in your browser.".printf (dlg_url));
				default:
					// translators: the first variable is the app name (Tuba),
					//				the second one is a url
					return _("If you proceed, %s will connect to \"%s\".".printf (Build.NAME, dlg_url));
			}
		}

		public bool open_special_card (string t_url) {
			switch (this) {
				case BASIC:
					Host.open_uri (t_url);
					return true;
				default:
					return false;
			}
		}

		public void parse_url (string t_url, out string special_host, out string special_api_url) throws Error {
			switch (this) {
				case PEERTUBE:
					var peertube_instance = GLib.Uri.parse (t_url, GLib.UriFlags.NONE);
					special_host = peertube_instance.get_host ();
					special_api_url = @"https://$(special_host)/api/v1/videos/$(Path.get_basename (peertube_instance.get_path ()))";
					break;
				case FUNKWHALE:
					var funkwhale_instance = GLib.Uri.parse (t_url, GLib.UriFlags.NONE);
					special_host = funkwhale_instance.get_host ();
					special_api_url = @"https://$(special_host)/api/v1/tracks/$(Path.get_basename (funkwhale_instance.get_path ()))";
					break;
				case BOOKWYRM:
					var bookwyrm_instance = GLib.Uri.parse (t_url, GLib.UriFlags.NONE);
					special_host = bookwyrm_instance.get_host ();
					var bookwyrm_id = Path.get_basename (Path.get_dirname (Path.get_dirname (t_url)));
					special_api_url = @"https://$(special_host)/book/$(bookwyrm_id).json";
					break;
				default:
					special_host = "";
					special_api_url = "";
					break;
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
			return kind == "link" && bookwyrm_regex.match (url);
		}
    }

	public static void open_special_card (CardSpecialType card_special_type, string card_url) {
		var privacy_dialog = app.question (
			card_special_type.to_dialog_title (),
			card_special_type.to_dialog_body (card_url),
			app.main_window,
			_("Proceed"),
			Adw.ResponseAppearance.DESTRUCTIVE
		);

		privacy_dialog.response.connect(res => {
			if (res == "yes") {
				if (card_special_type.open_special_card (card_url)) {
					privacy_dialog.destroy();
					return;
				};
				string special_api_url = "";
				string special_host = "";
				try {
					card_special_type.parse_url (card_url, out special_host, out special_api_url);
				} catch {
					Host.open_uri (card_url);
					privacy_dialog.destroy();
					return;
				}
				

				new Request.GET (special_api_url)
					.then ((sess, msg, in_stream) => {
						bool failed = true;
						var parser = Network.get_parser_from_inputstream(in_stream);
						var node = network.parse_node (parser);
						string res_url = "";
						API.BookWyrm? bookwyrm_obj = null;

						switch (card_special_type) {
							case API.PreviewCard.CardSpecialType.PEERTUBE:
								var peertube_obj = API.PeerTube.from (node);

								peertube_obj.get_video (card_url, out res_url, out failed);
								break;
							case API.PreviewCard.CardSpecialType.FUNKWHALE:
								var funkwhale_obj = API.Funkwhale.from (node);

								funkwhale_obj.get_track (special_host, out res_url, out failed);
								break;
							case API.PreviewCard.CardSpecialType.BOOKWYRM:
								bookwyrm_obj = API.BookWyrm.from (node);
								res_url = bookwyrm_obj.id;

								if (bookwyrm_obj.title != null && bookwyrm_obj.title != "") failed = false;
								break;
							default:
								assert_not_reached ();
						}

						if (failed || res_url == "") {
							Host.open_uri (card_url);
						} else {
							if (bookwyrm_obj == null) {
								app.main_window.show_media_viewer_remote_video (res_url, null, card_url);
							} else {
								app.main_window.show_book (bookwyrm_obj, card_url);
							}
						}
					})
					.on_error (() => {
						Host.open_uri (card_url);
					})
					.exec ();
			}
			privacy_dialog.destroy();
		});

		privacy_dialog.present ();
	}
}
