public class Tuba.API.Notification : Entity, Widgetizable {
	public class RelationshipSeveranceEvent : Entity {
		public string kind { get; set; }
		public string target_name { get; set; default = ""; }
		public int64 relationships_count { get; set; default = 0; }
		public int64 followers_count { get; set; default = 0; }
		public int64 following_count { get; set; default = 0; }

		public string to_string () {
			switch (kind) {
				case "user_domain_block":
					return GLib.ngettext (
						// translators: the first variable is an instance (e.g. mastodon.social), the others are numbers, e.g. '4 accounts you follow'
						"You have blocked %s, removing %s of your followers and %s account you follow.", "You have blocked %s, removing %s of your followers and %s accounts you follow.",
						(ulong) following_count
					).printf (
						"<b>%s</b>".printf (target_name),
						"<b>%lld</b>".printf (followers_count),
						"<b>%lld</b>".printf (following_count)
					);
				case "domain_block":
					return GLib.ngettext (
						// translators: the first variable is an instance (e.g. mastodon.social), the other two are numbers, e.g. '4 accounts you follow'
						"An admin has blocked %s, including %s of your followers and %s account you follow.", "An admin has blocked %s, including %s of your followers and %s accounts you follow.",
						(ulong) following_count
					).printf (
						"<b>%s</b>".printf (target_name),
						"<b>%lld</b>".printf (followers_count),
						"<b>%lld</b>".printf (following_count)
					);
				case "account_suspension":
					// translators: the first variable is a user handle so 'them' refers to that user
					return _("An admin has suspended %s, which means you can no longer receive updates from them or interact with them.").printf (
						"<b>%s</b>".printf (target_name)
					);
				default:
					assert_not_reached ();
			}
		}
	}

	public class ModerationWarning : Entity {
		public string id { get; set; }
	}

	public string id { get; set; }
	public API.Account account { get; set; }
	public string? kind { get; set; default = null; }
	public string? created_at { get; set; default = null; }
	public API.Status? status { get; set; default = null; }
	public string? emoji { get; set; default = null; }
	public string? emoji_url { get; set; default = null; }
	public API.Admin.Report? report { get; set; default = null; }
	public ModerationWarning? moderation_warning { get; set; default = null; }

	// the docs claim that 'relationship_severance_event'
	// is the one used but that is not true
	public RelationshipSeveranceEvent? event { get; set; default = null; }
	public RelationshipSeveranceEvent? relationship_severance_event { get; set; default = null; }

	public override void open () {
		switch (kind) {
			case InstanceAccount.KIND_SEVERED_RELATIONSHIPS:
				Host.open_url.begin (@"$(accounts.active.instance)/severed_relationships");
				break;
			case InstanceAccount.KIND_MODERATION_WARNING:
				string dispute_id = this.moderation_warning == null ? "" : this.moderation_warning.id;
				Host.open_url.begin (@"$(accounts.active.instance)/disputes/strikes/$dispute_id");
				break;
			case InstanceAccount.KIND_ADMIN_REPORT:
				if (report != null) {
					if (accounts.active.admin_mode) {
						var admin_window = new Dialogs.Admin.Window ();
						admin_window.present ();
						admin_window.open_reports ();
					} else {
						Host.open_url.begin (@"$(accounts.active.instance)/admin/reports/$(report.id)");
					}
				}
				break;
			case InstanceAccount.KIND_ANNUAL_REPORT:
				int year;
				if (this.created_at == null) {
					GLib.DateTime now = new GLib.DateTime.now_local ();
					year = now.get_month () >= 11 ? now.get_year () : now.get_year () - 1;
				} else {
					year = new GLib.DateTime.from_iso8601 (this.created_at, null).get_year ();
				}

				new Request.GET (@"/api/v1/annual_reports/$year")
					.with_account (accounts.active)
					.then ((in_stream) => {
						var parser = Network.get_parser_from_inputstream (in_stream);
						var node = network.parse_node (parser);
						API.AnnualReports.from (node).open (year);
					})
					.exec ();
				break;
			default:
				if (status != null) {
					status.open ();
				} else {
					account.open ();
				}
				break;
		}
	}

	public override Gtk.Widget to_widget () {
		switch (kind) {
			case InstanceAccount.KIND_FOLLOW:
			case InstanceAccount.KIND_FOLLOW_REQUEST:
				this.account.tuba_rs = new API.Relationship.for_account (this.account);
				return new Widgets.Account (this.account);
			case InstanceAccount.KIND_ADMIN_SIGNUP:
				this.account.tuba_rs = new API.Relationship.for_account (this.account);
				return new Widgets.Account (this.account) {
					// translators: as in just registered in the instance,
					//				this is a notification type only visible
					//				to admins
					additional_label = _("Signed Up")
				};
			case InstanceAccount.KIND_SEVERED_RELATIONSHIPS:
				RelationshipSeveranceEvent? t_event = event == null ? relationship_severance_event : event;
				return create_basic_card ("tuba-heart-broken-symbolic", t_event.to_string ());
			case InstanceAccount.KIND_MODERATION_WARNING:
				return create_basic_card ("tuba-police-badge2-symbolic", _("Your account has received a moderation warning"));
			case InstanceAccount.KIND_ADMIN_REPORT:
				return create_basic_card ("tuba-build-alt-symbolic", report.to_string (this.created_at));
			case InstanceAccount.KIND_ANNUAL_REPORT:
				int year = this.created_at == null ? new GLib.DateTime.now_local ().get_year () : new GLib.DateTime.from_iso8601 (this.created_at, null).get_year ();
				return create_basic_card (
					"tuba-birthday-symbolic",
					"<b>%s</b> %s".printf (
						_("Your %s #FediWrapped is ready!").printf (year.to_string ()),
						// translators: used in the #FediWrapped notifications, refer to the other #FediWrapped strings for more info
						_("Review your year's highlights and memorable moments on the Fediverse!")
					)
				);
			default:
				return new Widgets.Notification (this);
		}
	}

	private Gtk.Widget create_basic_card (string icon_name, string label) {
		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 16) {
			margin_top = 8,
			margin_bottom = 8,
			margin_start = 16,
			margin_end = 16
		};
		box.append (new Gtk.Image.from_icon_name (icon_name) {
			icon_size = Gtk.IconSize.LARGE
		});
		box.append (new Gtk.Label (label) {
			vexpand = true,
			xalign = 0.0f,
			use_markup = true,
			css_classes = {"title"},
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			hexpand = true
		});

		var row = new Widgets.ListBoxRowWrapper () {
			child = box,
		};
		row.open.connect (open);
		return row;
	}

	public virtual async GLib.Notification to_toast (InstanceAccount issuer, int others = 0) {
		Tuba.InstanceAccount.Kind res_kind;
		bool should_show_buttons = issuer == accounts.active;

		var kind_actor_name = account.display_name;
		if (others > 0) {
			//  translators: <user> (& <amount> others) <actions>
			//               for example: GeopJr (& 10 others) mentioned you
			kind_actor_name = _("%s (& %d others)").printf (account.display_name, others);
		}

		string? other_data = emoji;
		if (kind == InstanceAccount.KIND_ANNUAL_REPORT) {
			int year = this.created_at == null ? new GLib.DateTime.now_local ().get_year () : new GLib.DateTime.from_iso8601 (this.created_at, null).get_year ();
			other_data = year.to_string ();
		}

		issuer.describe_kind (kind, out res_kind, kind_actor_name, null, other_data);
		var toast = new GLib.Notification (res_kind.description);
		if (status != null) {
			var body = "";
			body += HtmlUtils.remove_tags (status.content);
			toast.set_body (body);
		}

		if (should_show_buttons) {
			switch (kind) {
				case InstanceAccount.KIND_SEVERED_RELATIONSHIPS:
				case InstanceAccount.KIND_ADMIN_REPORT:
				case InstanceAccount.KIND_ADMIN_SIGNUP:
				case InstanceAccount.KIND_ANNUAL_REPORT:
				case InstanceAccount.KIND_MODERATION_WARNING:
					toast.set_default_action ("app.goto-notifications");
					break;
				case InstanceAccount.KIND_FOLLOW_REQUEST:
					toast.set_default_action ("app.open-follow-requests");
					break;
				default:
					string var_string = account.url;
					if (status != null && status.url != null) {
						var_string = status.url;
					}

					toast.set_default_action_and_target_value (
						"app.open-status-url",
						new Variant.string (var_string)
					);
					break;
			}

			switch (kind) {
				case InstanceAccount.KIND_MENTION:
					if (status != null) {
						toast.add_button_with_target_value (
							_("Reply…"),
							"app.reply-to-status-uri",
							new Variant.tuple ({accounts.active.id, status.uri})
						);
					}
					break;
				case InstanceAccount.KIND_FOLLOW:
					toast.add_button_with_target_value (
						_("Remove from Followers"),
						"app.remove-from-followers",
						new Variant.tuple ({accounts.active.id, account.id})
					);
					toast.add_button_with_target_value (
						_("Follow Back"),
						"app.follow-back",
						new Variant.tuple ({accounts.active.id, account.id})
					);
					break;
				case InstanceAccount.KIND_FOLLOW_REQUEST:
					toast.add_button_with_target_value (
						_("Decline"),
						"app.answer-follow-request",
						new Variant.tuple ({accounts.active.id, account.id, false})
					);
					toast.add_button_with_target_value (
						_("Accept"),
						"app.answer-follow-request",
						new Variant.tuple ({accounts.active.id, account.id, true})
					);
					break;
			}
		}

		Icon? icon = null;
		if (Tuba.is_flatpak) {
			Bytes avatar_bytes = yield Tuba.Helper.Image.request_bytes (account.avatar);
			if (avatar_bytes != null)
				icon = new BytesIcon (avatar_bytes);
		} else {
			var icon_file = GLib.File.new_for_uri (account.avatar);
			icon = new FileIcon (icon_file);
		}

		if (icon != null)
			toast.set_icon (icon);

		return toast;
	}
}
