public class Tuba.Views.Collections : Views.TabbedBase {
	Views.ContentBase own;
	Views.ContentBase featured;
	Gtk.Button add_collection_button;

	construct {
		label = _("Collections");
	}

	public Collections () {
		app.refresh.connect (refresh);

		add_collection_button = new Gtk.Button.from_icon_name ("tuba-plus-large-symbolic") {
			css_classes = { "suggested-action" },
			// translators: headerbar button that creates a Mastodon Collection
			tooltip_text = _("New Collection"),
			sensitive = false
		};
		add_collection_button.clicked.connect (on_add);
		header.pack_end (add_collection_button);

		own = add_list_tab (
			// translators: 'Collections' is a Mastodon feature; you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			_("Your Collections"),
			"tuba-shapes-symbolic",
			// translators: 'Collections' is a Mastodon feature; you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			_("No Collections")
		);

		featured = add_list_tab (
			// tab title under Collections, aka "Collections Featuring You"
			_("Featuring You"),
			"tuba-person-symbolic",
			_("No Collections")
		);

		refresh_all (true);
	}

	private void on_add () {
		var dlg = new Dialogs.Collections ();
		dlg.refresh.connect (refresh);
		dlg.present (app.main_window);
	}

	private void refresh () {
		refresh_all ();
	}

	private void refresh_all (bool skip_mapped_check = false) {
		if (!skip_mapped_check && !this.get_mapped ()) return;

		new Request.GET (@"/api/v1/accounts/$(accounts.active.id)/collections")
			.with_account (accounts.active)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				var collections = API.Collections.from (node);

				API.Collection[] to_add = {};
				foreach (API.Collection collection in collections.collections) {
					to_add += collection;
				}
				own.model.splice (0, own.model.n_items, to_add);
				add_collection_button.sensitive = own.model.n_items < (accounts.active.role != null ? accounts.active.role.collection_limit : 10);
			})
			.on_error (own.on_error)
			.exec ();

		new Request.GET (@"/api/v1/accounts/$(accounts.active.id)/in_collections")
			.with_account (accounts.active)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				var collections = API.Collections.from (node);

				API.Collection[] to_add = {};
				foreach (API.Collection collection in collections.collections) {
					to_add += collection;
				}
				featured.model.splice (0, featured.model.n_items, to_add);
			})
			.on_error (featured.on_error)
			.exec ();
	}
}

public class Tuba.Views.CollectionList : Views.ContentBase {
	string for_user_id;
	public CollectionList (string for_user_id) {
		Object (
			label: _("Collections"),
			icon: "tuba-shapes-symbolic",
			empty_state_title: _("No Collections"),
			allow_nesting: true
		);

		this.for_user_id = for_user_id;
		app.refresh.connect (refresh);
		refresh_real (true);
	}

	private void refresh () {
		refresh_real ();
	}

	private void refresh_real (bool skip_mapped_check = false) {
		if (!skip_mapped_check && !this.get_mapped ()) return;

		new Request.GET (@"/api/v1/accounts/$for_user_id/collections")
			.with_account (accounts.active)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				var collections = API.Collections.from (node);

				API.Collection[] to_add = {};
				foreach (API.Collection collection in collections.collections) {
					to_add += collection;
				}
				this.model.splice (0, this.model.n_items, to_add);
			})
			.on_error (this.on_error)
			.exec ();
	}
}
