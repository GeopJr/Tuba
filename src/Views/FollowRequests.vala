public class Tuba.Views.FollowRequests : Views.Timeline {
	public FollowRequests () {
		Object (
			url: "/api/v1/follow_requests",
			label: _("Follow Requests"),
			icon: "address-book-new-symbolic",
			empty_state_title: _("No Follow Requests"),
			batch_size_min: 20
		);
	}

	construct {
		accepts = typeof (API.Account);
	}

	public override Gtk.Widget on_create_model_widget (Object obj) {
		var widget = base.on_create_model_widget (obj);
		var widget_account = widget as Widgets.Account;

		if (widget_account != null) {
			var fr_row = widget_account.add_fr_row ();
			fr_row.declined.connect ((fr_row, req) => on_decline.begin (fr_row, req, obj as Widgetizable));
			fr_row.accepted.connect ((fr_row, req) => on_accept.begin (fr_row, req, obj as Widgetizable));
		}

		return widget;
	}

	public async void on_accept (Widgets.FollowRequestRow fr_row, RequestV2 req, Widgetizable widget) {
		fr_row.sensitive = false;

		try {
			var in_stream = yield req.exec (null);
			Json.Parser parser = yield Network.get_parser_from_inputstream_async (in_stream);
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
		} catch (Error e) {
			warning (@"Couldn't perform accept: $(e.code) $(e.message)");
			app.toast ("%s: %s".printf (_("Error"), e.message));
			fr_row.sensitive = true;
		}
	}

	public async void on_decline (Widgets.FollowRequestRow fr_row, RequestV2 req, Widgetizable widget) {
		fr_row.sensitive = false;

		try {
			yield req.exec (null);
			uint indx;
			var found = model.find (widget, out indx);
			if (found)
				model.remove (indx);
		} catch (Error e) {
			warning (@"Couldn't perform decline: $(e.code) $(e.message)");
			app.toast ("%s: %s".printf (_("Error"), e.message));
			fr_row.sensitive = true;
		}
	}
}
