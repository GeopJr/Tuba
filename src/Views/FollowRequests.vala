public class Tuba.Views.FollowRequests : Views.Timeline {
    construct {
        url = "/api/v1/follow_requests";
        label = _("Follow Requests");
        icon = "address-book-new-symbolic";
        accepts = typeof (API.Account);
    }

    public override Gtk.Widget on_create_model_widget (Object obj) {
		var widget = base.on_create_model_widget (obj);
		var widget_status = widget as Widgets.Status;

		if (widget_status != null) {
            var fr_row = new Widgets.FollowRequestRow (widget_status.kind_instigator.id);
            fr_row.declined.connect ((fr_row, req) => on_decline (fr_row, req, obj as Widgetizable));
            fr_row.accepted.connect ((fr_row, req) => on_accept (fr_row, req, obj as Widgetizable));

            widget_status.content_column.append (fr_row);
        }

		return widget;
	}

    public void on_accept (Widgets.FollowRequestRow fr_row, Request req, Widgetizable widget) {
        fr_row.sensitive = false;
        req
			.then ((in_stream) => {
                var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				var relationship = Entity.from_json (typeof (API.Relationship), node) as API.Relationship;
                if (relationship.followed_by == true) {
                    uint indx;
                    var found = model.find (widget, out indx);
                    if (found)
                        model.remove (indx);
                } else {
                    fr_row.sensitive = true;
                }
			})
			.exec ();
    }

    public void on_decline (Widgets.FollowRequestRow fr_row, Request req, Widgetizable widget) {
        fr_row.sensitive = false;
        req
			.then (() => {
                uint indx;
                var found = model.find (widget, out indx);
                if (found)
                    model.remove (indx);
			})
			.exec ();
    }
}
