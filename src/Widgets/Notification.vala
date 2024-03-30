public class Tuba.Widgets.Notification : Widgets.Status {
	public API.Notification notification { get; construct set; }

	public Notification (API.Notification obj) {
		API.Status status;
		if (obj.status != null)
			status = obj.status;
		else
			status = new API.Status.from_account (obj.account);

		Object (
			notification: obj,
			kind_instigator: obj.account,
			kind: obj.kind,
			status: status
		);

		if (obj.kind == InstanceAccount.KIND_FOLLOW || obj.kind == InstanceAccount.KIND_FOLLOW_REQUEST) {
			actions.visible = false;
			visibility_indicator.visible = false;
			date_label.visible = false;
		}

		if (status.formal.account.is_self ()) {
			if (prev_card != null)
				prev_card.visible = false;
		}
	}

}
