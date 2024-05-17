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
						// translators: the first variable is an instance (e.g. mastodon.social), the second one is a number,
						//				this is the singular version, '1 account you follow',
						//				leave <b> and </b> as is
						_("You have blocked <b>%s</b>, removing <b>%lld</b> of your followers and <b>1</b> account you follow.").printf (
							target_name,
							followers_count
						),

						// translators: the first variable is an instance (e.g. mastodon.social), the other two are numbers,
						//				this is the plural version, '4 accounts you follow',
						//				leave <b> and </b> as is
						_("You have blocked <b>%s</b>, removing <b>%lld</b> of your followers and <b>%lld</b> accounts you follow.").printf (
							target_name,
							followers_count,
							following_count
						),
						(ulong) following_count
					);
				case "domain_block":
					return GLib.ngettext (
						// translators: the first variable is an instance (e.g. mastodon.social), the second one is a number,
						//				this is the singular version, '1 account you follow',
						//				leave <b> and </b> as is
						_("An admin has blocked <b>%s</b>, including <b>%lld</b> of your followers and <b>1</b> account you follow.").printf (
							target_name,
							followers_count
						),

						// translators: the first variable is an instance (e.g. mastodon.social), the other two are numbers,
						//				this is the plural version, '4 accounts you follow',
						//				leave <b> and </b> as is
						_("An admin has blocked <b>%s</b>, including <b>%lld</b> of your followers and <b>%lld</b> accounts you follow.").printf (
							target_name,
							followers_count,
							following_count
						),
						(ulong) following_count
					);
				case "account_suspension":
					// translators: the first variable is a user handle so 'them' refers to that user,
					//				leave <b> and </b> as is
					return _("An admin has suspended <b>%s</b>, which means you can no longer receive updates from them or interact with them.").printf (
						target_name
					);
				default:
					assert_not_reached ();
			}
		}
	}

	public class Report : Entity {
		public string id { get; set; }
		public string category { get; set; default="other"; }
		public string comment { get; set; default=""; }

		public string to_string (string? created_at) {
			// translators: the variable is a string report comment,
			//				leave <b> and </b> as is
			string t_comment = comment == "" ? comment : _("With the comment: <b>%s</b>").printf (comment);
			string t_reason_type = "";
			switch (category) {
				case "other":
					// translators: report category
					t_reason_type = _("Other");
					break;
				case "spam":
					// translators: report category
					t_reason_type = _("Spam");
					break;
				case "legal":
					// translators: report category
					t_reason_type = _("Legal");
					break;
				case "violation":
					// translators: report category
					t_reason_type = _("Rule Violation");
					break;
			}

			string t_reason = t_reason_type == ""
				? ""
				// translators: report notification reason,
				//				the variable is a string reason category (e.g. Spam),
				//				leave <b> and </b> as is
				: _("Reason: <b>%s</b>\n").printf (t_reason_type);

			string msg = created_at == null
				// translators: report notification
				? _("You've received a report\n")

				// translators: report notification with date,
				//				leave <b> and </b> as is
				: _("You've received a report on: <b>%s</b>\n").printf (DateTime.format_full (created_at));

			return @"$msg$t_reason$t_comment";
		}
	}

	public string id { get; set; }
	public API.Account account { get; set; }
	public string? kind { get; set; default = null; }
	public string? created_at { get; set; default = null; }
	public API.Status? status { get; set; default = null; }
	public Report? report { get; set; default = null; }

	// the docs claim that 'relationship_severance_event'
	// is the one used but that is not true
	public RelationshipSeveranceEvent? event { get; set; default = null; }
	public RelationshipSeveranceEvent? relationship_severance_event { get; set; default = null; }

	public override void open () {
		switch (kind) {
			case InstanceAccount.KIND_SEVERED_RELATIONSHIPS:
				Host.open_url (@"$(accounts.active.instance)/severed_relationships");
				break;
			case InstanceAccount.KIND_ADMIN_REPORT:
				if (report != null)
					Host.open_url (@"$(accounts.active.instance)/admin/reports/$(report.id)");
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
					cover_badge_label = _("Signed Up")
				};
			case InstanceAccount.KIND_SEVERED_RELATIONSHIPS:
				RelationshipSeveranceEvent? t_event = event == null ? relationship_severance_event : event;
				return create_basic_card ("tuba-heart-broken-symbolic", t_event.to_string ());
			case InstanceAccount.KIND_ADMIN_REPORT:
				return create_basic_card ("tuba-police-badge2-symbolic", report.to_string (this.created_at));
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
		box.append (new Gtk.Image.from_icon_name ("tuba-heart-broken-symbolic") {
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

		issuer.describe_kind (kind, out res_kind, kind_actor_name);
		var toast = new GLib.Notification (res_kind.description);
		if (status != null) {
			var body = "";
			body += HtmlUtils.remove_tags (status.content);
			toast.set_body (body);
		}

		if (should_show_buttons) {
			toast.set_default_action_and_target_value (
				"app.open-status-url",
				new Variant.string (
					status?.url ?? account.url
				)
			);

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
