// Ported from Chatty
// https://source.puri.sm/Librem5/chatty/-/merge_requests/1229

public class Tuba.Tracking {
	/* https://github.com/brave/brave-core/blob/5fcad3e35bac6fea795941fd8189a59d79d488bc/browser/net/brave_site_hacks_network_delegate_helper.cc#L29-L67 */
	public const string[] TRACKING_IDS = {
		// Strip any utm_ based ones
		"utm_",
		// https://github.com/brave/brave-browser/issues/4239
		"fbclid", "gclid", "msclkid", "mc_eid",
		// New Facebook one
		"mibexid",
		// https://github.com/brave/brave-browser/issues/9879
		"dclid",
		// https://github.com/brave/brave-browser/issues/13644
		"oly_anon_id", "oly_enc_id",
		// https://github.com/brave/brave-browser/issues/11579
		"_openstat",
		// https://github.com/brave/brave-browser/issues/11817
		"vero_conv", "vero_id",
		// https://github.com/brave/brave-browser/issues/13647
		"wickedid",
		// https://github.com/brave/brave-browser/issues/11578
		"yclid",
		// https://github.com/brave/brave-browser/issues/8975
		"__s",
		// https://github.com/brave/brave-browser/issues/17451
		"rb_clickid",
		// https://github.com/brave/brave-browser/issues/17452
		"s_cid",
		// https://github.com/brave/brave-browser/issues/17507
		"ml_subscriber", "ml_subscriber_hash",
		// https://github.com/brave/brave-browser/issues/18020
		"twclid",
		// https://github.com/brave/brave-browser/issues/18758
		"gbraid", "wbraid",
		// https://github.com/brave/brave-browser/issues/9019
		"_hsenc", "__hssc", "__hstc", "__hsfp", "hsCtaTracking",
		// https://github.com/brave/brave-browser/issues/22082
		"oft_id", "oft_k", "oft_lk", "oft_d", "oft_c", "oft_ck", "oft_ids", "oft_sk",
		// https://github.com/brave/brave-browser/issues/11580
		"igshid",
		// Instagram Threads
		"ad_id", "adset_id", "campaign_id", "ad_name", "adset_name", "campaign_name", "placement",
	};

	public static string strip_utm (string url) {
		if (!("?" in url)) return url;

		try {
			var uri = Uri.parse (url, UriFlags.NONE);
			return strip_utm_from_uri (uri).to_string ();
		} catch {
			return strip_utm_fallback (url);
		}
	}

	public static Uri strip_utm_from_uri (Uri uri) throws Error {
		string[] res_params = {};

		var iter = UriParamsIter (uri.get_query ());
		string key;
		string val;
		while (iter.next (out key, out val)) {
			var not_tracking_id = true;
			foreach (var id in TRACKING_IDS) {
				if (id in key.down ()) {
					not_tracking_id = false;
					break;
				}
			}

			if (not_tracking_id) res_params += @"$key=$val";
		}

		string? res_query = res_params.length > 0 ? string.joinv ("&", res_params) : null;
		return Uri.build (
			uri.get_flags (),
			uri.get_scheme (),
			uri.get_userinfo (),
			uri.get_host (),
			uri.get_port (),
			uri.get_path (),
			res_query,
			uri.get_fragment ()
		);
	}

	public static string strip_utm_fallback (string url) {
		var split_url = url.split_set ("?", 2);
		if (split_url[1].index_of_char ('=') == -1) return url;

		var str = @"$(split_url[0])?";

		var fragment_offset = split_url[1].last_index_of_char ('#');
		var fragment = "";
		if (fragment_offset > -1) {
			fragment = split_url[1].substring (fragment_offset);
			split_url[1] = split_url[1].slice (0, fragment_offset);
		}

		var query_params = split_url[1].split_set ("&");
		foreach (var param in query_params) {
			var not_tracking_id = true;

			foreach (var id in TRACKING_IDS) {
				var index_of_eq = param.index_of_char ('=');
				if (index_of_eq > -1 && id in param.slice (0, index_of_eq).down ()) {
					not_tracking_id = false;
					break;
				}
			}

			if (not_tracking_id) {
				str += @"$(param)&";
			}
		}

		return @"$(str.slice(0, -1))$fragment";
	}

	// Mastodon's url regex depends on other libraries and gets computed on runtime.
	// It includes every single TLD among other things. Let's instead use GLib's Uri
	// which will promote writing URIs fully (including the scheme).
	const string[] ALLOWED_SCHEMES = { "http", "https" };
	public static GLib.Uri[] extract_uris (string content) {
		GLib.Uri[] res = {};
		if (content.length == 0 || !("://" in content)) return res;

		foreach (var word in content.split_set (" \n\r\t'\"()[]")) {
			if (!("://" in word)) continue;
			try {
				var uri = GLib.Uri.parse (word, GLib.UriFlags.ENCODED);
				if (uri.get_scheme () in ALLOWED_SCHEMES)
					res += uri;
			} catch {}
		}

		return res;
	}

	public enum CleanupType {
		STRIP_TRACKING,
		SPECIFIC_LENGTH;
	}

	public static string cleanup_content_with_uris (owned string content, GLib.Uri[] uris, CleanupType cleanup_type, int characters_reserved_per_url = 23) {
		if (uris.length == 0) return content;

		int last_index = 0;
		switch (cleanup_type) {
			case CleanupType.STRIP_TRACKING:
				foreach (var uri in uris) {
					if (uri.get_query () == null) continue;
					try {
						string stripped = strip_utm_from_uri (uri).to_string ();
						string original = uri.to_string ();

						// 1 extra arguments for `string string.replace (string, string)' ???
						// content = content.replace (uri.to_string (), stripped, 1);
						last_index = content.index_of (original, last_index);
						if (last_index == -1) {
							last_index = 0;
							continue;
						}

						StringBuilder builder = new StringBuilder (content);
						builder.erase (last_index, original.length);
						builder.insert (last_index, stripped);

						content = builder.str;
					} catch {}
				}
				break;
			case CleanupType.SPECIFIC_LENGTH:
				if (characters_reserved_per_url <= 0) break;
				string replacement = string.nfill (characters_reserved_per_url, 'X');
				foreach (var uri in uris) {
					string original = uri.to_string ();

					last_index = content.index_of (original, last_index);
					if (last_index == -1) {
						last_index = 0;
						continue;
					}

					StringBuilder builder = new StringBuilder (content);
					builder.erase (last_index, original.length);
					builder.insert (last_index, replacement);

					content = builder.str;
				}
				break;
			default: break;
		}

		return content;
	}
}
