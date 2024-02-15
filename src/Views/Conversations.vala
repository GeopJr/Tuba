public class Tuba.Views.Conversations : Views.Timeline {
    construct {
        url = "/api/v1/conversations";
        label = _("Conversations");
        icon = "mail-unread-symbolic";
        accepts = typeof (API.Conversation);
        stream_event[InstanceAccount.EVENT_CONVERSATION].connect (on_new_post);
    }

    public override string? get_stream_url () {
		return account != null
            ? @"$(account.instance)/api/v1/streaming?stream=direct&access_token=$(account.access_token)"
            : null;
    }

    public override void on_content_changed () {
        for (uint i = 0; i < model.get_n_items (); i++) {
            var convo_obj = (API.Conversation) model.get_item (i);
            if (convo_obj.last_status == null) {
                model.remove (i);
            }
        }
		base.on_content_changed ();
	}

    public override void on_delete_post (Streamable.Event ev) {
		try {
			var convo_id = ev.get_string ();

			for (uint i = 0; i < model.get_n_items (); i++) {
				var convo_obj = (API.Conversation) model.get_item (i);
				if (convo_obj.last_status?.id == convo_id) {
					model.remove (i);
					break;
				}
			}
		} catch (Error e) {
			warning (@"Error getting String from json: $(e.message)");
		}
	}
}
