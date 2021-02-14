using Gtk;

public class Tootle.Dialogs.About : AboutDialog {

	public About () {
		Object (
			transient_for: window,
			modal: true,

			logo_icon_name: Build.DOMAIN,
			program_name: Build.NAME,
			version: Build.VERSION,
			website: Build.SUPPORT_WEBSITE,
			website_label: _("Report an issue"),
			license_type: License.GPL_3_0_ONLY,
			copyright: Build.COPYRIGHT
		);

		// For some obscure reason, const arrays produce duplicates in the credits.
		// Static functions seem to avoid this peculiar behavior.
		authors = Build.get_authors ();
		artists = Build.get_artists ();
		translator_credits = Build.TRANSLATOR != " " ? Build.TRANSLATOR : null;

		response.connect ((response_id) => {
			if (response_id == Gtk.ResponseType.CANCEL || 
			    response_id == Gtk.ResponseType.DELETE_EVENT) {
				hide_on_delete ();
			}
		});

		present ();
	}

}
