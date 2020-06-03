using Gtk;

public class Tootle.Views.Profile : Views.Timeline {

    public API.Account profile { get; construct set; }

    protected RadioButton filter_all;
    protected RadioButton filter_replies;
    protected RadioButton filter_media;

    protected Label relationship;
    protected Box actions;
    protected Button follow_button;
    protected MenuButton options_button;

    protected Label posts_label;
    protected Label following_label;
    protected Label followers_label;
    protected RadioButton posts_tab;
    protected RadioButton following_tab;
    protected RadioButton followers_tab;

    construct {
    	profile.notify["rs"].connect (on_rs_updated);

        var builder = new Builder.from_resource (@"$(Build.RESOURCES)ui/views/profile_header.ui");
        var hdr = builder.get_object ("grid") as Grid;
		column_view.pack_start (hdr, false, false, 0);
		column_view.reorder_child (hdr, 0);

		var avatar = builder.get_object ("avatar") as Widgets.Avatar;
		avatar.url = profile.avatar;

		var name = builder.get_object ("name") as Widgets.RichLabel;
		profile.bind_property ("display-name", name, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			var label = (string) src;
			target.set_string (@"<span size='x-large' weight='bold'>$label</span>");
			return true;
		});

		var handle = builder.get_object ("handle") as Widgets.RichLabel;
		profile.bind_property ("acct", handle, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string ("@" + (string) src);
			return true;
		});

		var note = builder.get_object ("note") as Widgets.RichLabel;
		profile.bind_property ("note", note, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string (Html.simplify ((string) src));
			return true;
		});

		actions = builder.get_object ("actions") as Box;
		follow_button = builder.get_object ("follow_button") as Button;
		follow_button.clicked.connect (on_follow_button_clicked);
		options_button = builder.get_object ("options_button") as MenuButton;
		relationship = builder.get_object ("relationship") as Label;

		posts_label = builder.get_object ("posts_label") as Label;
		profile.bind_property ("posts_count", posts_label, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
		    var val = (int64) src;
			target.set_string (_("%s Posts").printf (@"<b>$val</b>"));
			return true;
		});
		following_label = builder.get_object ("following_label") as Label;
		profile.bind_property ("following_count", following_label, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
		    var val = (int64) src;
			target.set_string (_("%s Follows").printf (@"<b>$val</b>"));
			return true;
		});
		followers_label = builder.get_object ("followers_label") as Label;
		profile.bind_property ("followers_count", followers_label, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
		    var val = (int64) src;
			target.set_string (_("%s Followers").printf (@"<b>$val</b>"));
			return true;
		});

		filter_all = builder.get_object ("filter_all") as RadioButton;
		filter_all.toggled.connect (on_refresh);
		filter_replies = builder.get_object ("filter_replies") as RadioButton;
		filter_replies.toggled.connect (on_refresh);
		filter_media = builder.get_object ("filter_media") as RadioButton;
		filter_media.toggled.connect (on_refresh);

		posts_tab = builder.get_object ("posts_tab") as RadioButton;
		posts_tab.toggled.connect (() => {
			if (posts_tab.active) on_refresh ();
		});
		following_tab = builder.get_object ("following_tab") as RadioButton;
		following_tab.toggled.connect (() => {
			if (following_tab.active) on_refresh ();
		});
		followers_tab = builder.get_object ("followers_tab") as RadioButton;
		followers_tab.toggled.connect (() => {
			if (followers_tab.active) on_refresh ();
		});
    }

    public Profile (API.Account acc) {
        Object (profile: acc);
        profile.get_relationship ();
    }

	protected void on_follow_button_clicked () {
		actions.sensitive = false;
		profile.set_following (!profile.rs.following);
	}

	protected void on_rs_updated () {
		var rs = profile.rs;
		var label = "";
		if (actions.sensitive = rs != null) {
			if (rs.requested)
				label = _("Sent follow request");
			else if (rs.followed_by && rs.following)
				label = _("Mutually follows you");
			else if (rs.followed_by)
				label = _("Follows you");

			foreach (Widget w in new Widget[] { follow_button, options_button }) {
				var ctx = w.get_style_context ();
				ctx.remove_class (STYLE_CLASS_SUGGESTED_ACTION);
				ctx.remove_class (STYLE_CLASS_DESTRUCTIVE_ACTION);
				ctx.add_class (rs.following ? STYLE_CLASS_DESTRUCTIVE_ACTION : STYLE_CLASS_SUGGESTED_ACTION);
			}

			var label2 = "";
			if (rs.followed_by && !rs.following)
				label2 = _("Follow back");
			else if (rs.following)
				label2 = _("Unfollow");
			else
				label2 = _("Follow");

			follow_button.label = label2;
		}

		relationship.label = label;
	}

    public override string get_req_url () {
        if (page_next != null)
            return page_next;

    	if (following_tab.active)
    		return @"/api/v1/accounts/$(profile.id)/following";
    	else if (followers_tab.active)
    		return @"/api/v1/accounts/$(profile.id)/followers";
    	else
        	return @"/api/v1/accounts/$(profile.id)/statuses";
    }

	public override Request append_params (Request req) {
		req.with_param ("exclude_replies", (!filter_replies.active).to_string ());
		req.with_param ("only_media", filter_media.active.to_string ());
		return base.append_params (req);
	}

    public override GLib.Object? to_entity (Json.Object? json) {
    	if (posts_tab.active)
        	return new API.Status (json);
        else {
        	var account = new API.Account (json);
        	return new API.Status.from_account (account);
        }
    }

    public static void open_from_id (int64 id){
        var url = "%s/api/v1/accounts/%lld".printf (accounts.active.instance, id);
        var msg = new Soup.Message ("GET", url);
        msg.priority = Soup.MessagePriority.HIGH;
        network.queue (msg, (sess, mess) => {
            var root = network.parse (mess);
            var acc = new API.Account (root);
            window.open_view (new Views.Profile (acc));
        }, (status, reason) => {
            network.on_error (status, reason);
        });
    }

}
