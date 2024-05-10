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
						//				this is the singular version, '1 account you follow'
						_("You have blocked <b>%s</b>, removing <b>%lld</b> of your followers and <b>1</b> account you follow.").printf (
							target_name,
							followers_count
						),

						// translators: the first variable is an instance (e.g. mastodon.social), the other two are numbers,
						//				this is the plural version, '4 accounts you follow'
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
						//				this is the singular version, '1 account you follow'
						_("An admin has blocked <b>%s</b>, including <b>%lld</b> of your followers and <b>1</b> account you follow.").printf (
							target_name,
							followers_count
						),

						// translators: the first variable is an instance (e.g. mastodon.social), the other two are numbers,
						//				this is the plural version, '4 accounts you follow'
						_("An admin has blocked <b>%s</b>, including <b>%lld</b> of your followers and <b>%lld</b> accounts you follow.").printf (
							target_name,
							followers_count,
							following_count
						),
						(ulong) following_count
					);
				case "account_suspension":
					// translators: the first variable is a user handle so 'them' refers to that user
					return _("An admin has suspended <b>%s</b>, which means you can no longer receive updates from them or interact with them.").printf (
						target_name
					);
				default:
					assert_not_reached ();
			}
		}
	}

	public string id { get; set; }
	public API.Account account { get; set; }
	public string? kind { get; set; default = null; }
	public API.Status? status { get; set; default = null; }

	// the docs claim that 'relationship_severance_event'
	// is the one used but that is not true
	public RelationshipSeveranceEvent? event { get; set; default = null; }
	public RelationshipSeveranceEvent? relationship_severance_event { get; set; default = null; }

	public override void open () {
		switch (kind) {
			case InstanceAccount.KIND_SEVERED_RELATIONSHIPS:
				Host.open_uri (@"$(accounts.active.instance)/severed_relationships");
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
			case InstanceAccount.KIND_SEVERED_RELATIONSHIPS:
				RelationshipSeveranceEvent? t_event = event == null ? relationship_severance_event : event;
				var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 16) {
					margin_top = 8,
					margin_bottom = 8,
					margin_start = 16,
					margin_end = 16
				};
				box.append (new Gtk.Image.from_icon_name ("tuba-heart-broken-symbolic") {
					icon_size = Gtk.IconSize.LARGE
				});
				box.append (new Gtk.Label (t_event.to_string ()) {
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
			default:
				return new Widgets.Notification (this);
		}
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
