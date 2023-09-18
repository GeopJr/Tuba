public class Tuba.Views.EditHistory : Views.Timeline {
    public EditHistory (string status_id) {
        Object (
            url: @"/api/v1/statuses/$(status_id)/history",
            label: _("Edit History"),
            icon: "document-edit-symbolic"
        );
    }

    public override Gtk.Widget on_create_model_widget (Object obj) {
		var widget = base.on_create_model_widget (obj);
		var widget_status = widget as Widgets.Status;

		widget_status.actions.visible = false;
		widget_status.can_be_opened = false;
		widget_status.menu_button.visible = false;
		widget_status.content.selectable = true;

		return widget_status;
	}

    public override void on_content_item_activated (uint pos) {}
}
