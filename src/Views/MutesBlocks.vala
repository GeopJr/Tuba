public class Tuba.Views.MutesBlocks : Views.TabbedBase {
	Views.ContentBase mutes;
	Views.ContentBase blocks;

	construct {
		// translators: shows your muted or blocked people
		label = _("Mutes & Blocks");
	}

	public MutesBlocks () {
		mutes = add_timeline_tab (
			// translators: view title of muted people
			_("Mutes"),
			"audio-volume-muted-symbolic",
			"/api/v1/mutes",
			typeof (API.Account),
			// translators: empty state title
			_("No Muted Accounts"),
			null,
			true
		);

		blocks = add_timeline_tab (
			// translators: view title of blocked people
			_("Blocks"),
			"tuba-error-symbolic",
			"/api/v1/blocks",
			typeof (API.Account),
			// translators: empty state title
			_("No Blocked Accounts"),
			null,
			true
		);
	}
}
