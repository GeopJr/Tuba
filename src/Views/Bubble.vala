public class Tuba.Views.Bubble : Views.Timeline {
	construct {
		url = "/api/v1/timelines/bubble";
		label = "Bubble"; // NOTE: Leave untranslated for now
		icon = "tuba-fish-symbolic";
		is_public = true;
	}
}
