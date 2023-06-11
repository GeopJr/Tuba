public class Tuba.API.Instance : Entity {
	public Gee.ArrayList<string>? languages { get; set; }
	public API.Mastodon.Configurations? configuration { get; set; default = null; }
	public int64 max_toot_chars { get; set; default = 0; }
	public API.Mastodon.Configuration.Polls? poll_limits { get; set; default = null; }
	public int64 upload_limit { get; set; default = 0; }
    public API.Pleroma? pleroma { get; set; default = null; }

    public int64 compat_status_max_media_attachments {
        get {
			if (configuration != null) {
                return configuration.statuses.max_media_attachments;
            }

            return 4;
		}
    }

    public int64 compat_status_max_characters {
        get {
			if (configuration != null) {
                return configuration.statuses.max_characters;
            }

            return max_toot_chars;
		}
    }

    public int64 compat_status_max_image_size {
        get {
			if (configuration != null) {
                return configuration.media_attachments.image_size_limit;
            }

            return upload_limit;
		}
    }

    public int64 compat_status_max_video_size {
        get {
            if (configuration != null) {
                return configuration.media_attachments.video_size_limit;
            }

            return upload_limit;
		}
    }

    public API.Mastodon.Configuration.Polls? compat_status_polls {
        get {
			if (configuration != null) {
                return configuration.polls;
            }

            return poll_limits;
		}
    }

    public int64 compat_status_poll_max_characters {
        get {
            var compat_polls = compat_status_polls;
            if (compat_polls != null) {
                return compat_polls.compat_status_poll_max_characters;
            }

            return 50;
        }
    }

    public int64 compat_status_poll_max_options {
        get {
            var compat_polls = compat_status_polls;
            if (compat_polls != null) {
                return compat_polls.max_options;
            }

            return 4;
        }
    }

    public int64 compat_status_poll_min_expiration {
        get {
            var compat_polls = compat_status_polls;
            if (compat_polls != null) {
                return compat_polls.min_expiration;
            }

            return 300;
        }
    }

    public int64 compat_status_poll_max_expiration {
        get {
            var compat_polls = compat_status_polls;
            if (compat_polls != null) {
                return compat_polls.max_expiration;
            }

            return 2629746;
        }
    }

    public static API.Instance from (Json.Node node) throws Error {
        return Entity.from_json (typeof (API.Instance), node) as API.Instance;
	}
}
