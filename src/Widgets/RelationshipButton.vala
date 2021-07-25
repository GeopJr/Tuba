using Gtk;

public class Tootle.Widgets.RelationshipButton : Button {

	public API.Relationship? rs { get; set; }
	protected SourceFunc? fn = null;

	construct {
		notify["rs"].connect (on_bound);
		clicked.connect (on_clicked);
	}

	protected void on_bound () {
		if (rs != null) {
			rs.invalidated.connect (invalidate);
			rs.request ();
		}
		invalidate ();
	}

	public void on_clicked () {
		if (fn != null) {
			fn ();
			fn = null;
		}
	}

	public void invalidate () {
		if (rs == null) {
			sensitive = false;
			label = _("Follow");
			fn = null;
			return;
		}

		sensitive = true;
		remove_css_class ("suggested-action");
		remove_css_class ("destructive-action");

		if (rs.blocking || rs.domain_blocking) {
			label = _("Unblock");
			// icon_name = "changes-allow-symbolic";
			fn = () => {
				if (rs.domain_blocking)
					activate_action ("domain_blocking", null);
				else if (rs.blocking)
					activate_action ("view.blocking", null);
				return true;
			};
			add_css_class ("destructive-action");
			return;
		}
		else if (rs.following || rs.requested) {
			label = _("Unfollow");
			// icon_name = "list-remove-symbolic";
			fn = () => {
				rs.modify ("unfollow");
				return true;
			};
			add_css_class ("destructive-action");
			return;
		}
		else if (!rs.following) {
			label = _("Follow");
			// icon_name = "list-add-symbolic";
			fn = () => {
				rs.modify ("follow");
				return true;
			};
			add_css_class ("suggested-action");
			return;
		}

	}

}
