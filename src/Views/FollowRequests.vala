public class Tooth.Views.FollowRequests : Views.Timeline {

    public FollowRequests () {
        label = _("Follow Requests");
        icon = "tooth-address-book-new-symbolic";
        url = "/api/v1/follow_requests";
        accepts = typeof (API.Account);
    }

    public override Gtk.Widget on_create_model_widget(Object obj) {
		var widget = base.on_create_model_widget(obj);
		var widget_status = widget as Widgets.Status;

		if (widget_status != null) {
            widget_status.fr_actions.visible = true;
            widget_status.decline_fr_button.clicked.connect(() => on_decline(widget_status, obj as Widgetizable));
            widget_status.accept_fr_button.clicked.connect(() => on_accept(widget_status, obj as Widgetizable));
        }

		return widget;
	}

    public void on_accept(Widgets.Status widget_status, Widgetizable widget) {
        widget_status.fr_actions.sensitive = false;
        new Request.POST (@"/api/v1/follow_requests/$(widget_status.kind_instigator.id)/authorize")
			.with_account (accounts.active)
			.then ((sess, msg) => {
				var node = network.parse_node (msg);
				var relationship = Entity.from_json (typeof (API.Relationship), node) as API.Relationship;
                if (relationship.followed_by == true) {
                    uint indx;
		            var found = model.find (widget, out indx);
		            if (found)
			            model.remove(indx);
                } else {
                    widget_status.fr_actions.sensitive = true;
                }
			})
			.exec ();
    }

    public void on_decline(Widgets.Status widget_status, Widgetizable widget) {
        widget_status.fr_actions.sensitive = false;
        new Request.POST (@"/api/v1/follow_requests/$(widget_status.kind_instigator.id)/reject")
			.with_account (accounts.active)
			.then ((sess, msg) => {
                uint indx;
		        var found = model.find (widget, out indx);
		        if (found)
			        model.remove(indx);
			})
			.exec ();
    }
}
