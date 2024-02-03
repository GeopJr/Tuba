public class Tuba.Views.Hashtag : Views.Timeline {
    bool t_following = false;
    string t_tag = "";
    public Hashtag (string tag, bool? following = null, string? url_basename = null) {
        Object (
            url: @"/api/v1/timelines/tag/$(url_basename ?? tag)",
            label: @"#$tag"
        );

        t_tag = tag;
        if (following != null) {
            t_following = following;
            create_follow_button ();
        } else {
            init_tag ();
        }
    }

    Gtk.Button follow_tag_btn = new Gtk.Button.with_label (_("Follow"));
    private void create_follow_button () {
        if (t_following) {
            follow_tag_btn.label = _("Unfollow");
            follow_tag_btn.add_css_class ("destructive-action");
        } else {
            follow_tag_btn.add_css_class ("suggested-action");
        }
        follow_tag_btn.clicked.connect (follow);

        header.pack_end (follow_tag_btn);
    }

    private void update_button () {
        if (t_following) {
            follow_tag_btn.label = _("Follow");
            follow_tag_btn.remove_css_class ("destructive-action");
            follow_tag_btn.add_css_class ("suggested-action");
        } else {
            follow_tag_btn.label = _("Unfollow");
            follow_tag_btn.remove_css_class ("suggested-action");
            follow_tag_btn.add_css_class ("destructive-action");
        }
        t_following = !t_following;
    }

    private void follow () {
        var action = "follow";
        if (t_following) {
            action = "unfollow";
        }
        update_button ();

        new Request.POST (@"/api/v1/tags/$t_tag/$action")
            .with_account (accounts.active)
            .then ((in_stream) => {
                var parser = Network.get_parser_from_inputstream (in_stream);
                var root = network.parse (parser);
				if (!root.has_member ("following")) {
                    update_button ();
                };
            })
            .exec ();
    }

    private void init_tag () {
        new Request.GET (@"/api/v1/tags/$t_tag")
            .with_account (accounts.active)
            .then ((in_stream) => {
                var parser = Network.get_parser_from_inputstream (in_stream);
                var node = network.parse_node (parser);
				var tag_info = API.Tag.from (node);
                t_following = tag_info.following;
                create_follow_button ();
            })
            .exec ();
    }

    public override string? get_stream_url () {
        var split_url = url.split ("/");
        var tag = split_url[split_url.length - 1];
        return account != null
            ? @"$(account.instance)/api/v1/streaming?stream=hashtag&tag=$tag&access_token=$(account.access_token)"
            : null;
    }

}
