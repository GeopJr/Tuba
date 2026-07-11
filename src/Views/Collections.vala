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

		refresh_collections_real.begin ();
		refresh_in_collections_real.begin ();
	}

	private async void refresh_collections_real () {
		var req = new RequestV2 (@"/api/v1/accounts/$(accounts.active.id)/collections") { account = accounts.active };
		try {
			var in_stream = yield req.exec (null);
			Json.Parser parser = yield Network.get_parser_from_inputstream_async (in_stream);
			var node = network.parse_node (parser);
			var collections = API.Collections.from (node);

			API.Collection[] to_add = {};
			foreach (API.Collection collection in collections.collections) {
				to_add += collection;
			}
			own.model.splice (0, own.model.n_items, to_add);
			add_collection_button.sensitive = own.model.n_items < (accounts.active.role != null ? accounts.active.role.collection_limit : 10);
		} catch (Error e) {
			own.on_error (e.code, e.message);
		}
	}

	private async void refresh_in_collections_real () {
		var req = new RequestV2 (@"/api/v1/accounts/$(accounts.active.id)/in_collections") { account = accounts.active };
		try {
			var in_stream = yield req.exec (null);
			Json.Parser parser = yield Network.get_parser_from_inputstream_async (in_stream);
			var node = network.parse_node (parser);
			var collections = API.Collections.from (node);

			API.Collection[] to_add = {};
			foreach (API.Collection collection in collections.collections) {
				to_add += collection;
			}
			featured.model.splice (0, featured.model.n_items, to_add);
		} catch (Error e) {
			featured.on_error (e.code, e.message);
		}
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
		refresh_real.begin (true);
	}

	private void refresh () {
		refresh_real.begin ();
	}

	private async void refresh_real (bool skip_mapped_check = false) {
		if (!skip_mapped_check && !this.get_mapped ()) return;

		var req = new RequestV2 (@"/api/v1/accounts/$for_user_id/collections") { account = accounts.active };
		try {
			var in_stream = yield req.exec (null);
			Json.Parser parser = yield Network.get_parser_from_inputstream_async (in_stream);
			var node = network.parse_node (parser);
			var collections = API.Collections.from (node);

			API.Collection[] to_add = {};
			foreach (API.Collection collection in collections.collections) {
				to_add += collection;
			}
			this.model.splice (0, this.model.n_items, to_add);
		} catch (Error e) {
			this.on_error (e.code, e.message);
		}
	}
}
