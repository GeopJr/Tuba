public enum Tootle.MarkupPolicy {

	// Remove all tags from the string
	DISALLOW,

	// Allow markup, remove unsupported tags from the input string
	ALLOW,

	// Allow markup, do nothing with the input string
	TRUST;

	public string process (string input) {
		switch (this) {
			case DISALLOW:
				return HtmlUtils.remove_tags (input);
			case ALLOW:
				return HtmlUtils.simplify (input);
			default:
				return input;
		}
	}

	public void apply (Widgets.RichLabel w) {
		w.use_markup = this != DISALLOW;
	}

}
