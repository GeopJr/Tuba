public class Tuba.Views.MutesBlocks : Views.TabbedBase {
	Views.ContentBaseListView mutes;
	Views.ContentBaseListView blocks;

	construct {
		label = _("Mutes & Blocks");
	}

	public MutesBlocks () {
		mutes = add_timeline_tab (
			_("Mutes"),
			"audio-volume-muted-symbolic",
			"/api/v1/mutes",
			typeof (API.Account),
			_("No Muted Accounts")
		);

		blocks = add_timeline_tab (
			_("Blocks"),
			"tuba-error-symbolic",
			"/api/v1/blocks",
			typeof (API.Account),
			_("No Blocked Accounts")
		);
	}
}
