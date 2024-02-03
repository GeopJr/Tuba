public class Tuba.Widgets.RelationshipButton : Gtk.Button {

	public API.Relationship? rs { get; set; }
	protected SourceFunc? fn = null;

	construct {
		notify["rs"].connect (on_bound);
		clicked.connect (on_clicked);
	}

	public string handle { get; set; default=""; }

	protected void on_bound () {
		if (rs != null) {
			rs.invalidated.connect (invalidate);
		}
		invalidate ();
	}

	public void on_clicked () {
		if (fn != null) {
			sensitive = false;
			fn ();

			fn = null;
		}
	}

	public virtual void invalidate () {
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
					rs.question_modify_block (handle, false);
				return true;
			};
			add_css_class ("destructive-action");
			return;
		} else if (rs.following || rs.requested) {
			label = _("Unfollow");
			fn = () => {
				rs.modify ("unfollow");
				return true;
			};
			add_css_class ("destructive-action");
			return;
		} else if (!rs.following) {
			label = _("Follow");
			fn = () => {
				rs.modify ("follow");
				return true;
			};
			add_css_class ("suggested-action");
			return;
		}

	}

}
