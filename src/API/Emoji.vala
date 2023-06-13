public class Tuba.API.Emoji : Entity {
	public string shortcode { get; set; }
	public string url { get; set; }
	public string category { get; set; default=_("Other"); }
	public bool visible_in_picker { get; set; default=true; }
	public bool is_other {
		get {
			return category == _("Other");
		}
	}
}
