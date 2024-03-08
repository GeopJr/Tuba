public class Tuba.Views.MutesBlocks : Views.TabbedBase {
	Views.ContentBase mutes;
	Views.ContentBase blocks;

	construct {
		label = _("Mutes & Blocks");
	}

	public MutesBlocks () {
		mutes = add_timeline_tab (
			_("Mutes"),
			"audio-volume-muted-symbolic",
			"/api/v1/mutes",
			typeof (API.Account)
		);

		blocks = add_timeline_tab (
			_("Blocks"),
			"tuba-error-symbolic",
			"/api/v1/blocks",
			typeof (API.Account)
		);
	}
}
