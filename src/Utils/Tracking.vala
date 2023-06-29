// Ported from Chatty
// https://source.puri.sm/Librem5/chatty/-/merge_requests/1229

public class Tuba.Tracking {
    /* https://github.com/brave/brave-core/blob/5fcad3e35bac6fea795941fd8189a59d79d488bc/browser/net/brave_site_hacks_network_delegate_helper.cc#L29-L67 */
    public const string[] tracking_ids = {
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
            foreach (var id in tracking_ids) {
                if (id in key.down ()) {
                    not_tracking_id = false;
                    break;
                }
            }

            if (not_tracking_id) res_params += @"$key=$val";
        }

        string? res_query = res_params.length > 0 ? string.joinv("&", res_params) : null;
        return Uri.build (
            uri.get_flags (),
            uri.get_scheme(),
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
            fragment = split_url[1].substring(fragment_offset);
            split_url[1] = split_url[1].slice(0, fragment_offset);
        }

        var query_params = split_url[1].split_set ("&");
        foreach (var param in query_params) {
            var not_tracking_id = true;

            foreach (var id in tracking_ids) {
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
}
