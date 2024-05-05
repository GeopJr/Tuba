public class Tuba.Views.EditHistory : Views.Timeline {
	public EditHistory (string status_id) {
		Object (
			url: @"/api/v1/statuses/$(status_id)/history",
			label: _("Edit History"),
			icon: "tuba-edit-symbolic",
			empty_state_title: _("No Edit History")
		);
	}

	public override Gtk.Widget on_create_model_widget (Object obj) {
		var widget = base.on_create_model_widget (obj);
		var widget_status = widget as Widgets.Status;

		widget_status.actions.visible = false;
		widget_status.menu_button.visible = false;
		#if USE_LISTVIEW
			widget_status.can_be_opened = false;
			widget_status.content.selectable = true;
		#else
			widget_status.activatable = false;
		#endif

		return widget_status;
	}

	#if USE_LISTVIEW
		public override void on_content_item_activated (uint pos) {}
	#endif
}
