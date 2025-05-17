public class Tuba.Widgets.Notification : Widgets.Status {
	public API.Notification notification { get; construct set; }

	public Notification (API.Notification obj, bool with_kind = true) {
		API.Status status;
		if (obj.status != null)
			status = obj.status;
		else
			status = new API.Status.from_account (obj.account);

		if (obj.emoji_url != null) {
			API.Emoji custom_reaction = new API.Emoji () {
				shortcode = obj.emoji.slice (1, -1),
				url = obj.emoji_url
			};

			if (obj.account.emojis != null) {
				obj.account.emojis.add (custom_reaction);
			} else {
				var arr = new Gee.ArrayList<API.Emoji> ();
				arr.add (custom_reaction);
				obj.account.emojis = arr;
			}
		}

		Object (
			other_data: obj.emoji,
			notification: obj,
			kind_instigator: with_kind ? obj.account : null,
			kind: with_kind ? obj.kind : null,
			status: status
		);

		switch (obj.kind) {
			case InstanceAccount.KIND_FOLLOW:
			case InstanceAccount.KIND_FOLLOW_REQUEST:
				actions.visible = false;
				visibility_indicator.visible = false;
				date_label.visible = false;
				break;
			case InstanceAccount.KIND_FAVOURITE:
			case InstanceAccount.KIND_REBLOG:
			case InstanceAccount.KIND_PLEROMA_REACTION:
			case InstanceAccount.KIND_REACTION:
				this.add_css_class ("can-be-dimmed");
				break;
		}

		if (status.formal.account.is_self ()) {
			if (prev_card != null)
				prev_card.visible = false;
		}
	}

}
