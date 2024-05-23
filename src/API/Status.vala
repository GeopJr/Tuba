public class Tuba.API.Status : Entity, Widgetizable {

	~Status () {
		debug (@"[OBJ] Destroyed $(uri ?? "")");
	}

	public string id { get; set; }
	public API.Account account { get; set; }
	public string uri { get; set; }
	public string? spoiler_text { get; set; default = null; }
	public string? in_reply_to_id { get; set; default = null; }
	public string? in_reply_to_account_id { get; set; default = null; }
	public string content { get; set; default = ""; }
	public StatusApplication? application { get; set; default = null; }
	public int64 replies_count { get; set; default = 0; }
	public int64 reblogs_count { get; set; default = 0; }
	public int64 favourites_count { get; set; default = 0; }
	public string created_at { get; set; default = "0"; }
	public bool reblogged { get; set; default = false; }
	public bool favourited { get; set; default = false; }
	public bool bookmarked { get; set; default = false; }
	public bool sensitive { get; set; default = false; }
	public bool muted { get; set; default = false; }
	public bool pinned { get; set; default = false; }
	public string? edited_at { get; set; default = null; }
	public string visibility { get; set; default = settings.default_post_visibility; }
	public API.Status? reblog { get; set; default = null; }
	public API.Status? quote { get; set; default = null; }
	//  public API.Akkoma? akkoma { get; set; default = null; }
	public Gee.ArrayList<API.Mention>? mentions { get; set; default = null; }
	public Gee.ArrayList<API.EmojiReaction>? reactions { get; set; default = null; }
	public Gee.ArrayList<API.EmojiReaction>? emoji_reactions { get; set; default = null; }
	public API.Pleroma.Status? pleroma { get; set; default = null; }
	public Gee.ArrayList<API.Attachment>? media_attachments { get; set; default = null; }
	public API.Poll? poll { get; set; default = null; }
	public Gee.ArrayList<API.Emoji>? emojis { get; set; }
	public API.PreviewCard? card { get; set; default = null; }
	public Gee.ArrayList<API.Filters.FilterResult>? filtered { get; set; default = null; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "reactions":
			case "emoji-reactions":
				return typeof (API.EmojiReaction);
			case "mentions":
				return typeof (API.Mention);
			case "media-attachments":
				return typeof (API.Attachment);
			case "emojis":
				return typeof (API.Emoji);
			case "filtered":
				return typeof (API.Filters.FilterResult);
		}

		return base.deserialize_array_type (prop);
	}

	public bool tuba_filter_hidden {
		get {
			if (filtered == null || filtered.size == 0) return false;

			bool res = false;
			filtered.@foreach (e => {
				if (e.filter.tuba_hidden) {
					res = true;
					return false;
				}
				return true;
			});

			return res;
		}
	}

	public string? tuba_filter_warn {
		owned get {
			if (filtered == null || filtered.size == 0) return null;

			string? res = null;
			filtered.@foreach (e => {
				if (!e.filter.tuba_hidden) {
					res = e.filter.title;
					return false;
				}
				return true;
			});

			return res;
		}
	}

	public Tuba.Views.Thread.ThreadRole tuba_thread_role { get; set; default = Tuba.Views.Thread.ThreadRole.NONE; }
	public bool tuba_spoiler_revealed { get; set; default = settings.show_spoilers; }
	public bool tuba_translatable { get; set; default = false; }

	//  public string clean_content {
	//      get {
	//          if (quote != null && akkoma != null && akkoma.source != null && akkoma.source.content != null) {
	//              return akkoma.source.content;
	//          }

	//          return content;
	//      }
	//  }

	private string _language = settings.default_language;
	public string language {
		get {
			return _language;
		}
		set {
			if (value != null) tuba_translatable = true;
			_language = value ?? settings.default_language;
		}
	}

	public Gee.HashMap<string, string>? emojis_map {
		owned get {
			return gen_emojis_map ();
		}
	}

	private Gee.HashMap<string, string>? gen_emojis_map () {
		var res = new Gee.HashMap<string, string> ();
		if (emojis != null && emojis.size > 0) {
			emojis.@foreach (e => {
				res.set (e.shortcode, e.url);
				return true;
			});
		}

		return res;
	}

	public Gee.ArrayList<API.EmojiReaction>? compat_status_reactions {
		get {
			if (emoji_reactions != null) {
				return emoji_reactions;
			} else if (pleroma != null && pleroma.emoji_reactions != null) {
				return pleroma.emoji_reactions;
			}

			return reactions;
		}
	}

	public string? t_url { get; set; }
	public string? url {
		owned get { return this.get_modified_url (); }
		set { this.t_url = value; }
	}
	string? get_modified_url () {
		if (this.t_url == null) {
			if (this.uri == null) return null;
			return this.uri.replace (@"$id/activity", id);
		}
		return this.t_url;
	}

	public bool is_edited {
		get { return edited_at != null; }
	}

	public Status formal {
		get { return reblog ?? this; }
	}

	public bool has_spoiler {
		get {
			return !(formal.spoiler_text == null || formal.spoiler_text == "");
		}
	}

	public bool can_be_quoted {
		get {
			return this.formal.visibility != "direct" && this.formal.visibility != "private";
		}
	}

	public bool can_be_boosted {
		get {
			return this.formal.visibility != "direct"
				&& (
					this.formal.visibility != "private"
					|| this.formal.account.is_self ()
				);
		}
	}

	public static Status from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Status), node) as API.Status;
	}

	public Status.empty () {
		Object (
			id: ""
		);
	}

	public Status.from_account (API.Account account) {
		Object (
			id: "",
			account: account,
			created_at: account.created_at,
			emojis: account.emojis
		);

		if (account.note == "")
			content = "";
		else if ("\n" in account.note)
			content = account.note.split ("\n")[0];
		else
			content = account.note;
	}

	public override Gtk.Widget to_widget () {
		return new Widgets.Status (this);
	}

	public override void open () {
		app.main_window.open_view (new Views.Thread (formal));
	}

	public bool is_mine {
		get {
			return formal.account.id == accounts.active.id;
		}
	}

	public bool has_media {
		get {
			return media_attachments != null && !media_attachments.is_empty;
		}
	}

	public virtual string get_reply_mentions () {
		var result = "";
		if (account.acct != accounts.active.acct)
			result = @"$(account.handle) ";

		if (mentions != null) {
			foreach (var mention in mentions) {
				var equals_current = mention.acct == accounts.active.acct;
				var already_mentioned = mention.acct in result;

				if (!equals_current && !already_mentioned)
					result += @"$(mention.handle) ";
			}
		}

		return result;
	}

	private Request action (string action) {
		var req = new Request.POST (@"/api/v1/statuses/$(formal.id)/$action").with_account (accounts.active);
		req.priority = Soup.MessagePriority.HIGH;
		return req;
	}

	public Request favourite_req () {
		return action ("favourite");
	}

	public Request unfavourite_req () {
		return action ("unfavourite");
	}

	public Request bookmark_req () {
		return action ("bookmark");
	}

	public Request unbookmark_req () {
		return action ("unbookmark");
	}

	public enum ReblogVisibility {
		PUBLIC,
		UNLISTED,
		PRIVATE;

		public string to_string () {
			switch (this) {
				case PUBLIC:
					return "public";
				case UNLISTED:
					return "unlisted";
				case PRIVATE:
					return "private";
				default:
					return "";
			}
		}

		public static ReblogVisibility? from_string (string id) {
			switch (id) {
				case "public":
					return PUBLIC;
				case "unlisted":
					return UNLISTED;
				case "private":
					return PRIVATE;
				default:
					return null;
			}
		}
	}

	public Request reblog_req (ReblogVisibility? visibility = null) {
		var req = action ("reblog");
		if (visibility != null)
			req.with_form_data ("visibility", visibility.to_string ());

		return req;
	}

	public Request unreblog_req () {
		return action ("unreblog");
	}

	public Request annihilate () {
		return new Request.DELETE (@"/api/v1/statuses/$id")
			.with_account (accounts.active);
	}
}
