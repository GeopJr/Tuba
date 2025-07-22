public class Tuba.Views.Admin.Page.Dashboard : Views.Admin.Page.Base {
	private Adw.PreferencesGroup? stats_group = null;
	const string[] KEYS = {"new_users", "active_users", "interactions", "opened_reports", "resolved_reports"};
	private string[] titles;
	// Most of the mess here is the order. We need to be liberal on what
	// the server returns but also keep the same order which we can achieve
	// by dynamically keeping track of what has finished.
	private int requests = 0;

	construct {
		this.title = _("Dashboard");

		// translators: title in admin dashboard stats
		titles = {_("New Users"), _("Active Users"), _("Interactions"), _("Reports Opened"), _("Reports Resolved")};
		populate_stats ();

		// translators: group title in admin dashboard window
		do_dimension_request ("sources", _("Sign-up Sources"), 8);
		// translators: group title in admin dashboard window
		do_dimension_request ("languages", _("Top Active Languages"), 8);
		// translators: group title in admin dashboard window
		do_dimension_request ("servers", _("Top Active Servers"), 8);
		// translators: group title in admin dashboard window
		do_dimension_request ("software_versions", _("Software"), 4);
		// translators: group title in admin dashboard window
		do_dimension_request ("space_usage", _("Space Usage"), 4);
	}

	private void add_stat (Adw.ActionRow row) {
		stats_group.visible = true;
		stats_group.add (row);
	}

	private void update_requests (int change) {
		this.requests += change;
		this.spinning = this.requests > 0;
	}

	private Adw.PreferencesGroup create_group (string title) {
		var group = new Adw.PreferencesGroup () {
			title = title,
			visible = false
		};
		this.add_to_page (group);

		return group;
	}

	private void populate_stats (int i = 0) {
		if (i >= KEYS.length) return;

		if (stats_group == null) {
			stats_group = create_group (_("Stats"));
		}

		var next_i = i + 1;
		populate_stat (KEYS[i], titles[i], next_i);
	}

	private void populate_stat (string key, string title, int next_i) {
		update_requests (1);
		new Request.POST ("/api/v1/admin/measures")
			.with_account (accounts.active)
			.body_json (get_dimensions_body (key))
			.then ((in_stream) => {
				Network.get_parser_from_inputstream_async.begin (in_stream, (obj, res) => {
					try {
						var parser = Network.get_parser_from_inputstream_async.end (res);
						Network.parse_array (parser, node => {
							if (node != null) {
								var dimension = API.Admin.Dimension.from (node);
								if (dimension.key == key && dimension.total != null) {
									add_stat (
										new Adw.ActionRow () {
											title = title,
											subtitle = dimension.total,
											use_markup = false,
											subtitle_selectable = true
										}
									);

									if (next_i > -1) {
										populate_stats (next_i);
									}
								}
							}
						});
					} catch (Error e) {
						critical (@"Couldn't parse json: $(e.code) $(e.message)");
					}
				});
				update_requests (-1);
			})
			.on_error ((code, message) => {
				add_toast (message);
				update_requests (-1);
			})
			.exec ();
	}

	private void do_dimension_request (string key, string title, int limit) {
		update_requests (1);
		var group = create_group (title);
		new Request.POST ("/api/v1/admin/dimensions")
			.with_account (accounts.active)
			.body_json (get_dimensions_body (key, limit))
			.then ((in_stream) => {
				Network.get_parser_from_inputstream_async.begin (in_stream, (obj, res) => {
					try {
						var parser = Network.get_parser_from_inputstream_async.end (res);
						Network.parse_array (parser, node => {
							if (node != null) {
								var dimension = API.Admin.Dimension.from (node);
								if (dimension.key == key && dimension.data != null && dimension.data.size > 0) {
									foreach (var entry in dimension.data) {
										group.add (
											new Adw.ActionRow () {
												title = entry.human_key,
												subtitle = entry.human_value != null ? entry.human_value : entry.value,
												use_markup = false,
												subtitle_selectable = true
											}
										);
										group.visible = true;
									}
								}
							}
						});
					} catch (Error e) {
						critical (@"Couldn't parse json: $(e.code) $(e.message)");
					}
				});
				update_requests (-1);
			})
			.on_error ((code, message) => {
				add_toast (message);
				update_requests (-1);
			})
			.exec ();
	}

	private static Json.Builder get_dimensions_body (string key, int limit = 0) {
		var now = new GLib.DateTime.now_local ();
		var end = new GLib.DateTime.now_local ();
		now = now.add_days (-29);

		var builder = new Json.Builder ();
		builder.begin_object ();

		builder.set_member_name ("start_at");
		builder.add_string_value (now.format ("%F"));

		builder.set_member_name ("keys");
		builder.begin_array ();
		builder.add_string_value (key);
		builder.end_array ();

		if (limit > 0) {
			builder.set_member_name ("limit");
			builder.add_int_value (limit);
		}

		builder.set_member_name ("end_at");
		builder.add_string_value (end.format ("%F"));

		builder.end_object ();

		return builder;
	}
}
