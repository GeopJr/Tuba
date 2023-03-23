public class Tuba.Views.EditHistory : Views.Timeline {
    public EditHistory (string status_id) {
        Object (
            url: @"/api/v1/statuses/$(status_id)/history",
            label: _("Edit History"),
            icon: "document-edit-symbolic"
        );
    }

    public override Gtk.Widget on_create_model_widget(Object obj) {
		var widget = base.on_create_model_widget(obj);
		var widget_status = widget as Widgets.Status;

		widget_status.actions.visible = false;
		widget_status.activatable = false;

		return widget;
	}
}
