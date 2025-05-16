public class Tuba.Views.List : Views.Timeline {
	public API.List list { get; set; }

	public List (API.List l) {
		Object (
			uid: 2,
			url: @"/api/v1/timelines/list/$(l.id)",
			label: l.title,
			icon: "tuba-list-compact-symbolic",
			list: l
		);

		this.list.notify["title"].connect (title_changed);
		update_stream ();
	}

	protected override void build_header () {
		base.build_header ();

		var edit_btn = new Gtk.Button () {
			icon_name = "document-edit-symbolic",
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			css_classes = { "flat" },
			tooltip_text = _("Edit")
		};
		edit_btn.clicked.connect (on_edit);

		header.pack_end (edit_btn);
	}

	private void on_edit () {
		new Dialogs.ListEdit (list).present (app.main_window);
	}

	private void title_changed () {
		this.label = GLib.Markup.escape_text (this.list.title);
		GLib.Idle.add (accounts.active.gather_fav_lists);
	}

	public override string? get_stream_url () {
		if (list == null)
			return null;
		return account != null
			? @"$(account.instance)/api/v1/streaming?stream=list&list=$(list.id)&access_token=$(account.access_token)"
			: null;
	}
}
